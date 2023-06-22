defmodule MetaStore.Aggregates.TransformerLifespan do
  @behaviour Commanded.Aggregates.AggregateLifespan

  alias Core.Events.TransformerDeleted

  def after_event(%TransformerDeleted{}), do: :stop
  def after_event(_event), do: :infinity
  def after_command(_command), do: :infinity
  def after_error(_error), do: :stop
end

