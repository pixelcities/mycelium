defmodule Maestro do
  @moduledoc """
  Documentation for `Maestro`.
  """

  @app Maestro.Application.get_app()

  import Ecto.Query, warn: false

  alias Core.Commands.{CreateTask, AssignTask, UnAssignTask, CompleteTask, CancelTask, FailTask}
  alias Maestro.Projections.Task
  alias Maestro.Repo


  ## Database getters

  def get_tasks(opts \\ []) do
    tenant = Keyword.fetch!(opts, :tenant)

    Repo.all((from t in Task,
      where: t.is_completed == false and t.is_cancelled == false
    ), prefix: tenant)
  end

  def get_tasks_by_worker(worker, opts \\ []) do
    tenant = Keyword.fetch!(opts, :tenant)

    Repo.all((from t in Task,
      where: t.is_completed == false and t.is_cancelled == false and t.worker == ^worker
    ), prefix: tenant)
  end


  ## Commands

  def schedule_task(attrs, %{"ds_id" => ds_id} = metadata), do: dispatch(CreateTask.new(attrs), metadata, ds_id, :strong)

  def assign_task(attrs, %{"ds_id" => ds_id} = metadata), do: dispatch(AssignTask.new(attrs), metadata, ds_id)

  def unassign_task(attrs, %{"ds_id" => ds_id} = metadata), do: dispatch(UnAssignTask.new(attrs), metadata, ds_id)

  def complete_task(attrs, %{"user_id" => user_id, "ds_id" => ds_id} = metadata) do
    task = CompleteTask.new(Map.merge(attrs, %{"worker" => user_id}))

    dispatch(task, metadata, ds_id, :strong)
  end

  def cancel_task(attrs, %{"ds_id" => ds_id} = metadata), do: dispatch(CancelTask.new(attrs), metadata, ds_id, :strong)

  def fail_task(attrs, %{"ds_id" => ds_id} = metadata), do: dispatch(FailTask.new(attrs), metadata, ds_id)

  defp dispatch(command, metadata, ds_id, consistency \\ :eventual) do
    with :ok <- @app.validate_and_dispatch(command, consistency: consistency, application: Module.concat(@app, ds_id), metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end

end
