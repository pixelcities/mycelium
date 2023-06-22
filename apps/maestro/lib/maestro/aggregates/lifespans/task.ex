defmodule Maestro.Aggregates.TaskLifespan do
  @behaviour Commanded.Aggregates.AggregateLifespan

  alias Core.Events.{TaskCancelled, TaskCompleted, TaskFailed}

  def after_event(%TaskCancelled{}), do: :stop
  def after_event(%TaskFailed{}), do: :stop
  def after_event(%TaskCompleted{is_completed: is_completed}) when is_completed, do: :stop
  def after_event(_event), do: :infinity
  def after_command(_command), do: :infinity
  def after_error(_error), do: :stop
end

