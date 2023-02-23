defmodule Maestro do
  @moduledoc """
  Documentation for `Maestro`.
  """

  @app Maestro.Application.get_app()

  import Ecto.Query, warn: false

  alias Core.Commands.{CreateTask, AssignTask, UnAssignTask, CompleteTask, CancelTask}
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

  def schedule_task(attrs, %{ds_id: ds_id} = metadata) do
    task =
      attrs
      |> CreateTask.new()

    with :ok <- @app.validate_and_dispatch(task, consistency: :strong, application: Module.concat(@app, ds_id), metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end

  def assign_task(attrs, %{ds_id: ds_id} = metadata) do
    task =
      attrs
      |> AssignTask.new()

    with :ok <- @app.validate_and_dispatch(task, consistency: :eventual, application: Module.concat(@app, ds_id), metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end

  def unassign_task(attrs, %{ds_id: ds_id} = metadata) do
    task = UnAssignTask.new(attrs)

    with :ok <- @app.validate_and_dispatch(task, consistency: :eventual, application: Module.concat(@app, ds_id), metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end

  def complete_task(attrs, %{user_id: user_id, ds_id: ds_id} = metadata) do
    task = CompleteTask.new(Map.merge(attrs, %{"worker" => user_id}))

    with :ok <- @app.validate_and_dispatch(task, consistency: :strong, application: Module.concat(@app, ds_id), metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end

  def cancel_task(attrs, %{ds_id: ds_id} = metadata) do
    with :ok <- @app.validate_and_dispatch(CancelTask.new(attrs), consistency: :strong, application: Module.concat(@app, ds_id), metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end

end
