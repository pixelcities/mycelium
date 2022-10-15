defmodule MetaStore.Workflows.AddCollectionInput do
  use Commanded.Event.Handler,
    name: __MODULE__,
    consistency: :strong

  alias Core.Events.CollectionTargetAdded

  def handle(%CollectionTargetAdded{} = event, metadata) do
    fun =
      if MetaStore.get_transformer!(event.target, tenant: Map.get(metadata, "ds_id")) do
        &MetaStore.add_transformer_input(&1, &2)
      else
        &MetaStore.add_widget_input(&1, &2)
      end

    with {:ok, _data} <- fun.(%{
      id: event.target,
      workspace: event.workspace,
      collection: event.id
    }, metadata) do
      :ok
    end
  end
end
