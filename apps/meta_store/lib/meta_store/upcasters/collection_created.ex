defimpl Commanded.Event.Upcaster, for: Core.Events.CollectionCreated do
  def upcast(%Core.Events.CollectionCreated{} = event, metadata) do
    %Core.Events.CollectionCreated{event | ds: Map.get(metadata, "ds_id")}
  end
end
