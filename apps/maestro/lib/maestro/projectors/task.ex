defmodule Maestro.Projectors.Task do
  use Commanded.Projections.Ecto,
    repo: Maestro.Repo,
    name: "Projectors.Task",
    consistency: :strong

  alias Core.Events.{TaskCreated, TaskAssigned, TaskUnAssigned, TaskCancelled, TaskCompleted}
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
      Ecto.Changeset.change(t, worker: task.worker)
    end, prefix: ds_id)
  end

  project %TaskUnAssigned{} = task, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Ecto.Multi.run(:get_task, fn repo, _changes ->
      {:ok, repo.get(Task, task.id, prefix: ds_id) }
    end)
    |> Ecto.Multi.update(:update, fn %{get_task: t} ->
      Ecto.Changeset.change(t, worker: nil)
    end, prefix: ds_id)
  end

  project %TaskCancelled{} = task, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Ecto.Multi.run(:get_task, fn repo, _changes ->
      {:ok, repo.get(Task, task.id, prefix: ds_id) }
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

end
