defmodule Maestro.Workflows.AssignTransformerTask do
  use Commanded.Event.Handler,
    name: __MODULE__,
    consistency: :strong

  alias Maestro.Allocator
  alias Core.Events.{TaskCreated, TaskUnAssigned, TaskCompleted}

  def handle(%TaskCreated{type: "transformer"} = event, _metadata), do: Allocator.assign_workers()
  def handle(%TaskUnAssigned{} = event, _metadata), do: Allocator.assign_workers()
  def handle(%TaskCompleted{} = event, _metadata) when length(event.fragments) > 0, do: Allocator.assign_workers()

end
