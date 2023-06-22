defmodule DataStore.Aggregates.DatasetLifespan do
  @behaviour Commanded.Aggregates.AggregateLifespan

  alias Core.Events.DatasetDeleted

  def after_event(%DatasetDeleted{}), do: :stop
  def after_event(_event), do: :infinity
  def after_command(_command), do: :infinity
  def after_error(_error), do: :stop
end

