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

    Enum.each(all, fn {user_id, meta, tasks} ->
      ds_id = Map.get(meta, :ds_id)

      # Get a list of recently executed tasks, no need to bother checking these
      # again for a (short) while. This also takes care of a worker getting the
      # same task again and again on error.
      recent_tasks = get_recent_tasks(tasks)
      {recent_task_ids, _} = Enum.unzip(recent_tasks)

      if ds_id != nil do
        assign_bundle_tasks(user_id, ds_id)

        case assign_task(user_id, ds_id, recent_task_ids) do
          nil -> nil
          task_id -> :ets.insert(workers, {user_id, meta, apply_task(recent_tasks, task_id)})
        end
      end
    end)

    {:reply, :ok, workers}
  end

  @impl true
  def handle_call(:clean, _from, workers) do
    all = :ets.tab2list(workers)

    live_workers = Enum.group_by(all,
      fn {_worker_id, meta, _tasks} -> Map.get(meta, :ds_id) end,
      fn {worker_id, _meta, _tasks} -> worker_id end
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
      :ets.insert(workers, {user_id, meta, []})

      assign_bundle_tasks(user_id, ds_id)

      case assign_task(user_id, ds_id, []) do
        nil -> nil
        task_id -> :ets.insert(workers, {user_id, meta, apply_task([], task_id)})
      end
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


  @ttl 15

  defp get_recent_tasks(tasks) do
    tasks
    |> Enum.reject(fn {_task_id, ttl} -> ttl > :os.system_time(:seconds) end)
  end

  defp apply_task(tasks, task_id) do
    tasks
    |> Enum.concat([{task_id, :os.system_time(:seconds) + @ttl}])
  end

  defp assign_bundle_tasks(user_id, ds_id) do
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

  # Returns either the assigned task id, or nil
  defp assign_task(user_id, ds_id, recent_tasks) do
    Enum.reduce_while(Maestro.get_tasks(tenant: ds_id, ignore_list: recent_tasks), nil, fn(task, _acc) ->
      if task.type == "transformer" or task.type == "widget" do
        case Maestro.assign_task(%{
          id: task.id,
          type: task.type,
          task: task.task,
          worker: user_id,
          fragments: task.fragments,
          metadata: task.metadata
        }, %{
          "ds_id" => ds_id
        }) do
          {:error, :task_outdated} ->
            Maestro.cancel_task(%{id: task.id, is_cancelled: true}, %{"ds_id" => ds_id})
            {:cont, nil}

          {:error, :task_noop} ->
            Logger.debug("Task \"#{task.id}\" for worker \"#{user_id}\" was a noop")
            {:cont, nil}

          {:error, e} ->
            Logger.error("Error assigning task \"#{task.id}\": " <> inspect(e))
            {:cont, nil}

          _ ->
            Logger.info("Assigning task \"#{task.id}\" to worker \"#{user_id}\"")
            {:halt, task.id}
        end
      end
    end)
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
