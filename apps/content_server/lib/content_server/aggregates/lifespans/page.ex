defmodule ContentServer.Aggregates.PageLifespan do
  @behaviour Commanded.Aggregates.AggregateLifespan

  alias Core.Events.PageDeleted

  def after_event(%PageDeleted{}), do: :stop
  def after_event(_event), do: :infinity
  def after_command(_command), do: :infinity
  def after_error(_error), do: :stop
end

