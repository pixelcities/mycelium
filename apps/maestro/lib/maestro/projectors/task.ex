defmodule Maestro.Projectors.Task do
  use Commanded.Projections.Ecto,
    repo: Maestro.Repo,
    name: "Projectors.Task",
    consistency: :strong

  @impl Commanded.Projections.Ecto
  def schema_prefix(_event, %{"ds_id" => ds_id} = _metadata), do: ds_id

  require Logger

  alias Core.Events.{TaskCreated, TaskAssigned, TaskUnAssigned, TaskCancelled, TaskCompleted, TaskFailed}
  alias Maestro.Projections.Task

  project %TaskCreated{} = task, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Ecto.Multi.insert(:insert, %Task{
      id: task.id,
      causation_id: task.causation_id,
      type: task.type,
      task: task.task,
      worker: task.worker,
      fragments: task.fragments,
      metadata: task.metadata
    }, prefix: ds_id)
  end

  project %TaskAssigned{} = task, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Ecto.Multi.run(:get_task, fn repo, _changes ->
      {:ok, repo.get(Task, task.id, prefix: ds_id) }
    end)
    |> Ecto.Multi.update(:update, fn %{get_task: t} ->
      Ecto.Changeset.change(t,
        worker: task.worker,
        worker_history: Enum.uniq(t.worker_history ++ [task.worker])
      )
    end, prefix: ds_id)
  end

  project %TaskUnAssigned{} = task, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Ecto.Multi.run(:get_task, fn repo, _changes ->
      case repo.get(Task, task.id, prefix: ds_id) do
        nil -> {:error, :already_deleted}
        t -> {:ok, t}
      end
    end)
    |> Ecto.Multi.update(:update, fn %{get_task: t} ->
      Ecto.Changeset.change(t, worker: nil)
    end, prefix: ds_id)
  end

  project %TaskCancelled{} = task, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Ecto.Multi.run(:get_task, fn repo, _changes ->
      case repo.get(Task, task.id, prefix: ds_id) do
        nil -> {:error, :already_deleted}
        t -> {:ok, t}
      end
    end)
    |> Ecto.Multi.update(:update, fn %{get_task: t} ->
      Ecto.Changeset.change(t, is_cancelled: true)
    end, prefix: ds_id)
  end

  project %TaskCompleted{} = task, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Ecto.Multi.run(:get_task, fn repo, _changes ->
      {:ok, repo.get(Task, task.id, prefix: ds_id) }
    end)
    |> Ecto.Multi.update(:update, fn %{get_task: t} ->
      Ecto.Changeset.change(t,
        is_completed: task.is_completed,
        metadata: task.metadata,
        worker: nil
      )
    end, prefix: ds_id)
  end

  project %TaskFailed{} = task, %{"ds_id" => ds_id} = _metadata, fn multi ->
    multi
    |> Ecto.Multi.run(:get_task, fn repo, _changes ->
      case repo.get(Task, task.id, prefix: ds_id) do
        nil -> {:error, :already_deleted}
        t -> {:ok, t}
      end
    end)
    |> Ecto.Multi.delete(:delete, fn %{get_task: t} -> t end)
  end


  # Error handlers

  @impl true
  def error({:error, :already_deleted}, _event, _failure_context) do
    :skip
  end

  @impl true
  def error({:error, error}, _event, _failure_context) do
    Logger.error(fn -> "Task projector is skipping event due to:" <> inspect(error) end)

    :skip
  end


  # Issue commands after the read model is guaranteed to be updated

  @impl Commanded.Projections.Ecto
  def after_update(%TaskCreated{type: "transformer"}, _metadata, _changes) do
    Maestro.Allocator.assign_workers()

    :ok
  end

  @impl Commanded.Projections.Ecto
  def after_update(%TaskUnAssigned{}, _metadata, _changes) do
    Maestro.Allocator.assign_workers()

    :ok
  end

  @impl Commanded.Projections.Ecto
  def after_update(%TaskCompleted{} = event, _metadata, _changes)
    when length(event.fragments) > 0
  do
    Maestro.Allocator.assign_workers()

    :ok
  end

  @impl Commanded.Projections.Ecto
  def after_update(_event, _metadata, _changes), do: :ok

end
