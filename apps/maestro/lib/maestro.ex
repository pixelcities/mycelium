defmodule Maestro do
  @moduledoc """
  Documentation for `Maestro`.
  """

  @app Maestro.Application.get_app()

  alias Core.Commands.{CreateTask, AssignTask, CompleteTask}


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

end
