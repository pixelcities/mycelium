defmodule Maestro do
  @moduledoc """
  Documentation for `Maestro`.
  """

  @app Maestro.Application.get_app()

  import Ecto.Query, warn: false

  alias Core.Commands.{CreateTask, AssignTask, UnAssignTask, CompleteTask}
  alias Maestro.Projections.Task
  alias Maestro.Repo

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

  def complete_task(attrs, %{user_id: _user_id, ds_id: ds_id} = metadata) do
    task =
      attrs
      |> CompleteTask.new()

    with :ok <- @app.validate_and_dispatch(task, consistency: :strong, application: Module.concat(@app, ds_id), metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end

  def get_tasks(opts \\ []) do
    tenant = Keyword.fetch!(opts, :tenant)

    Repo.all((from t in Task,
      where: t.is_completed == false and t.is_cancelled == false
    ), prefix: tenant)
  end

end
