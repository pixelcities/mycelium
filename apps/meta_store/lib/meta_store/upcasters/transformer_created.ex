defimpl Commanded.Event.Upcaster, for: Core.Events.TransformerCreated do
  def upcast(%Core.Events.TransformerCreated{} = event, metadata) do
    %Core.Events.TransformerCreated{event | ds: Map.get(metadata, "ds_id")}
  end
end
