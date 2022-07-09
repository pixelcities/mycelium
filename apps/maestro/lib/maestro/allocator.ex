defmodule Maestro.Allocator do
  @moduledoc """
  Receives and processes live user availability updates

  Whenever a user comes online, this may be a suitable worker for a pending
  task. The availability is tracked, while also looping over the open tasks
  to cross reference if this worker is required.
  """

  use GenServer

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
    all = :ets.tab2list(workers)
    {:reply, all, workers}
  end

  @impl true
  def handle_call(:assign, _from, workers) do
    all = :ets.tab2list(workers)

    Enum.each(all, fn {user_id, meta} ->
      ds_id = Map.get(meta, :ds_id)

      if ds_id != nil do
        assign_bundle_tasks(user_id, ds_id)
        assign_transformer_tasks(user_id, ds_id)
      end
    end)

    {:reply, :ok, workers}
  end

  @impl true
  def handle_call(:clean, _from, workers) do
    all = :ets.tab2list(workers)

    live_workers = Enum.map(all, fn {worker_id, _meta} -> worker_id end)
    clean_tasks(live_workers, :ds1)

    {:reply, :ok, workers}
  end

  @impl true
  def handle_cast({:register, user_id, meta}, workers) do
    worker = :ets.lookup(workers, user_id)
    ds_id = Map.get(meta, :ds_id)

    if length(worker) == 0 and ds_id != nil do
      :ets.insert(workers, {user_id, meta})

      assign_bundle_tasks(user_id, ds_id)
      assign_transformer_tasks(user_id, ds_id)
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

      Maestro.schedule_task(task, %{ds_id: ds_id})
      Maestro.assign_task(Map.put(task, :worker, user_id), %{ds_id: ds_id})
    end
  end

  defp assign_transformer_tasks(user_id, ds_id) do
    Enum.each(Maestro.get_tasks(), fn(task) ->
      if task.type == "transformer" do
        Maestro.assign_task(%{
          id: task.id,
          type: task.type,
          task: task.task,
          worker: user_id,
          fragments: task.fragments,
          metadata: task.metadata
        }, %{
          ds_id: ds_id
        })
      end
    end)
  end

  defp unassign_tasks(user_id, ds_id) do
    Enum.each(Maestro.get_tasks(), fn task ->
      if task.worker == user_id do
        Maestro.unassign_task(%{
          id: task.id
        }, %{ds_id: ds_id})
      end
    end)
  end

  defp clean_tasks(workers, ds_id) do
    Enum.each(Maestro.get_tasks(), fn task ->
      if task.worker not in workers do
        Maestro.unassign_task(%{
          id: task.id
        }, %{ds_id: ds_id})
      end
    end)
  end

end
