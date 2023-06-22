defmodule MetaStore.Aggregates.WidgetLifespan do
  @behaviour Commanded.Aggregates.AggregateLifespan

  alias Core.Events.WidgetDeleted

  def after_event(%WidgetDeleted{}), do: :stop
  def after_event(_event), do: :infinity
  def after_command(_command), do: :infinity
  def after_error(_error), do: :stop
end

