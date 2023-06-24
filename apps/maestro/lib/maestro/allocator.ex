defmodule Maestro.Allocator do
  @moduledoc """
  Receives and processes live user availability updates

  Whenever a user comes online, this may be a suitable worker for a pending
  task. The availability is tracked, while also looping over the open tasks
  to cross reference if this worker is required.
  """

  use GenServer
  require Logger

  alias KeyX.Protocol

  ## Client

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, name, opts)
  end

  def list_workers() do
    GenServer.call(__MODULE__, :list)
  end

  def assign_workers() do
    GenServer.call(__MODULE__, :assign)
  end

  def clean_workers() do
    GenServer.call(__MODULE__, :clean)
  end

  def register_worker(user_id, meta) do
    GenServer.cast(__MODULE__, {:register, user_id, meta})
  end

  def deregister_worker(user_id) do
    GenServer.cast(__MODULE__, {:deregister, user_id})
  end


  ## Callbacks

  @impl true
  def init(table) do
    workers = :ets.new(table, [:set, :protected, :named_table])

    {:ok, workers}
  end

  @impl true
  def handle_call(:list, _from, workers) do
    {:reply, :ets.tab2list(workers), workers}
  end

  @impl true
  def handle_call(:assign, _from, workers) do
    all = :ets.tab2list(workers)

    # Assign regular tasks per ds group
    live_workers =
      Enum.group_by(all,
        fn {_worker_id, meta} -> Map.get(meta, :ds_id) end,
        fn {worker_id, _meta} -> worker_id end
      )

    Enum.each(live_workers, fn {ds_id, user_ids} ->
      assign_tasks(user_ids, ds_id)
    end)

    # Assign bundle tasks per user
    Enum.each(all, fn {user_id, meta} ->
      assign_bundle_task(user_id, Map.get(meta, :ds_id))
    end)

    {:reply, :ok, workers}
  end

  @impl true
  def handle_call(:clean, _from, workers) do
    all = :ets.tab2list(workers)

    live_workers = Enum.group_by(all,
      fn {_worker_id, meta} -> Map.get(meta, :ds_id) end,
      fn {worker_id, _meta} -> worker_id end
    )

    Enum.each(live_workers, fn {ds_id, user_ids} ->
      clean_tasks(user_ids, ds_id)
    end)

    {:reply, :ok, workers}
  end

  @impl true
  def handle_cast({:register, user_id, meta}, workers) do
    worker = :ets.lookup(workers, user_id)
    ds_id = Map.get(meta, :ds_id)

    if length(worker) == 0 and ds_id != nil do
      :ets.insert(workers, {user_id, meta})

      assign_bundle_task(user_id, ds_id)
      assign_tasks([user_id], ds_id)
    end

    {:noreply, workers}
  end

  @impl true
  def handle_cast({:deregister, user_id}, workers) do
    worker = :ets.lookup(workers, user_id)
    :ets.delete(workers, user_id)

    if length(worker) == 1 do
      {_user_id, meta} = hd(worker)
      unassign_tasks(user_id, meta.ds_id)
    end

    {:noreply, workers}
  end


  defp assign_bundle_task(_user_id, ds_id) when is_nil(ds_id), do: {:error, :ds_must_not_be_nil}
  defp assign_bundle_task(user_id, ds_id) do
    nr_bundles = Protocol.get_nr_bundles_by_user_id!(user_id)

    if nr_bundles < 5 do
      id = UUID.uuid4()

      task = %{
        id: id,
        type: "protocol",
        task: %{
          "instruction" => "add_bundles"
        }
      }

      Maestro.schedule_task(task, %{"ds_id" => ds_id})
      Maestro.assign_task(Map.put(task, :worker, user_id), %{"ds_id" => ds_id})
    end
  end

  defp assign_tasks(_user_ids, ds_id) when is_nil(ds_id), do: {:error, :ds_must_not_be_nil}
  defp assign_tasks(user_ids, ds_id) do
    Enum.reduce(Maestro.get_tasks(tenant: ds_id), user_ids, fn task, workers ->
      # Ensure that workers that have already seen this task are deprioritized. Then,
      # attempt to assign the task to them and stop the iterator.
      chosen_worker =
        workers
        |> Enum.sort_by(fn worker -> worker in task.worker_history end)
        |> Enum.reduce_while(nil, fn worker, _acc ->
          if task.type == "transformer" or task.type == "widget" do
            case Maestro.assign_task(%{
              id: task.id,
              type: task.type,
              task: task.task,
              worker: worker,
              fragments: task.fragments,
              metadata: task.metadata
            }, %{
              "ds_id" => ds_id
            }) do
              {:error, :task_outdated} ->
                Maestro.cancel_task(%{id: task.id, is_cancelled: true}, %{"ds_id" => ds_id})
                {:cont, nil}

              {:error, :task_noop} ->
                Logger.debug("Task \"#{task.id}\" for worker \"#{worker}\" was a noop")
                {:cont, nil}

              {:error, e} ->
                Logger.error("Error assigning task \"#{task.id}\": " <> inspect(e))
                {:cont, nil}

              _ ->
                Logger.info("Assigning task \"#{task.id}\" to worker \"#{worker}\"")
                {:halt, worker}
            end
          else
            {:cont, nil}
          end
        end)

      # If a worker was found, move it to the back of the list so that following tasks
      # have a higher chance to be assigned to another worker.
      Enum.sort_by(workers, fn worker -> worker == chosen_worker end)
    end)

    :ok
  end

  defp unassign_tasks(user_id, ds_id) do
    Enum.each(Maestro.get_tasks_by_worker(user_id, tenant: ds_id), fn task ->
      Maestro.unassign_task(%{
        id: task.id
      }, %{"ds_id" => ds_id})
    end)
  end

  defp clean_tasks(workers, ds_id) do
    Enum.each(Maestro.get_tasks(tenant: ds_id), fn task ->
      if task.worker not in workers do
        Maestro.unassign_task(%{
          id: task.id
        }, %{"ds_id" => ds_id})
      end
    end)
  end

end
