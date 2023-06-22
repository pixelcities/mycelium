defmodule ContentServer.Aggregates.ContentLifespan do
  @behaviour Commanded.Aggregates.AggregateLifespan

  alias Core.Events.ContentDeleted

  def after_event(%ContentDeleted{}), do: :stop
  def after_event(_event), do: :infinity
  def after_command(_command), do: :infinity
  def after_error(_error), do: :stop
end

