defmodule MetaStore.Workflows.AddCollectionInput do
  use Commanded.Event.Handler,
    name: __MODULE__,
    consistency: :strong

  alias Core.Events.CollectionTargetAdded

  def handle(%CollectionTargetAdded{} = event, metadata) do
    with {:ok, _data} <- MetaStore.add_transformer_input(%{
      id: event.target,
      workspace: event.workspace,
      collection: event.id
    }, metadata) do
      :ok
    end
  end
end
