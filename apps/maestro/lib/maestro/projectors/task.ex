defmodule Maestro.Projectors.Task do
  use Commanded.Projections.Ecto,
    repo: Maestro.Repo,
    name: "Projectors.Task",
    consistency: :strong

  alias Core.Events.{TaskCreated, TaskAssigned, TaskCancelled, TaskCompleted}
  alias Maestro.Projections.Task

  project %TaskCreated{} = task, _metadata, fn multi ->
    multi
    |> Ecto.Multi.insert(:insert, %Task{
      id: task.id,
      causation_id: task.causation_id,
      type: task.type,
      task: task.task,
      worker: task.worker,
      fragments: task.fragments
    })
  end

  project %TaskAssigned{} = task, _metadata, fn multi ->
    multi
    |> Ecto.Multi.run(:get_task, fn repo, _changes ->
      {:ok, repo.get(Task, task.id) }
    end)
    |> Ecto.Multi.update(:update, fn %{get_task: t} ->
      Ecto.Changeset.change(t, worker: task.worker)
    end)
  end

  project %TaskCancelled{} = task, _metadata, fn multi ->
    multi
    |> Ecto.Multi.run(:get_task, fn repo, _changes ->
      {:ok, repo.get(Task, task.id) }
    end)
    |> Ecto.Multi.update(:update, fn %{get_task: t} ->
      Ecto.Changeset.change(t, is_cancelled: true)
    end)
  end

  project %TaskCompleted{} = task, _metadata, fn multi ->
    multi
    |> Ecto.Multi.run(:get_task, fn repo, _changes ->
      {:ok, repo.get(Task, task.id) }
    end)
    |> Ecto.Multi.update(:update, fn %{get_task: t} ->
      Ecto.Changeset.change(t, is_completed: task.is_completed)
    end)
  end

end
