defmodule MetaStore.Aggregates.ConceptLifespan do
  @moduledoc false

  @behaviour Commanded.Aggregates.AggregateLifespan

  alias Core.Events.ConceptDeleted

  def after_event(%ConceptDeleted{}), do: :stop

  def after_event(_event), do: :infinity
  def after_command(_command), do: :infinity
  def after_error(_error), do: :stop
end

