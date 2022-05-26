defmodule Maestro.Projectors.Task do
  use Commanded.Projections.Ecto,
    repo: Maestro.Repo,
    name: "Projectors.Task",
    consistency: :strong

  alias Core.Events.{TaskCreated, TaskAssigned, TaskCompleted}
  alias Maestro.Projections.Task

  project %TaskCreated{} = task, _metadata, fn multi ->
    multi
    |> Ecto.Multi.insert(:insert, %Task{
      id: task.id,
      type: task.type,
      task: task.task,
      worker: task.worker
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

  project %TaskCompleted{} = task, _metadata, fn multi ->
    multi
    |> Ecto.Multi.run(:get_task, fn repo, _changes ->
      {:ok, repo.get(Task, task.id) }
    end)
    |> Ecto.Multi.update(:update, fn %{get_task: t} ->
      Ecto.Changeset.change(t, is_completed: true)
    end)
  end

end
