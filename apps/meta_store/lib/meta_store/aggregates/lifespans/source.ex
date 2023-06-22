defmodule MetaStore.Aggregates.SourceLifespan do
  @behaviour Commanded.Aggregates.AggregateLifespan

  alias Core.Events.SourceDeleted

  def after_event(%SourceDeleted{}), do: :stop
  def after_event(_event), do: :infinity
  def after_command(_command), do: :infinity
  def after_error(_error), do: :stop
end

