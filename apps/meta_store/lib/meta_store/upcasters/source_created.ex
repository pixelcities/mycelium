defimpl Commanded.Event.Upcaster, for: Core.Events.SourceCreated do
  def upcast(%Core.Events.SourceCreated{} = event, metadata) do
    %Core.Events.SourceCreated{event | ds: Map.get(metadata, "ds_id")}
  end
end
