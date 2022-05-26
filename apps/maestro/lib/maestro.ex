defmodule Maestro do
  @moduledoc """
  Documentation for `Maestro`.
  """

  @app Maestro.Application.get_app()

  import Ecto.Query, warn: false

  alias Core.Commands.{CreateTask, AssignTask, CompleteTask}
  alias Maestro.Projections.Task
  alias Maestro.Repo

  def schedule_task(attrs, metadata \\ %{}) do
    task =
      attrs
      |> CreateTask.new()

    with :ok <- @app.validate_and_dispatch(task, consistency: :strong, application: Module.concat([@app, :ds1]), metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end

  def assign_task(attrs, metadata \\ %{}) do
    task =
      attrs
      |> AssignTask.new()

    with :ok <- @app.validate_and_dispatch(task, consistency: :strong, application: Module.concat([@app, :ds1]), metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end

  def complete_task(attrs, %{user_id: _user_id} = metadata) do
    task =
      attrs
      |> CompleteTask.new()

    with :ok <- @app.validate_and_dispatch(task, consistency: :strong, application: Module.concat([@app, :ds1]), metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end

  def get_tasks(_attrs \\ %{}) do
    Repo.all(from t in Task,
      where: t.is_completed == false
    )
  end

end
