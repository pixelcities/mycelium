defmodule Maestro.Utils do

  def get_transformer_identifiers(transformer) do
    Enum.filter(Map.values(Map.get(transformer.wal, "identifiers")), fn %{"id" => id, "type" => type} = identifier ->
      # Sanity check
      (id != transformer.id) and

      # Skip table identifiers
      (type == "column") and

      # New columns will still have to be created, so they aren't valid yet
      (Map.get(identifier, "action") != "add")
    end)
  end

  def get_widget_identifiers(%MetaStore.Projections.Widget{} = widget) do
    columnIds = Map.values(Map.filter(widget.settings, fn {k, _v} ->
      String.contains?(String.downcase(k, :ascii), "column")
    end))

    # Make sure these are indeed column identifiers
    collection = MetaStore.get_collection!(widget.collection, tenant: widget.__meta__.prefix())

    Enum.reject(columnIds, fn id ->
      id not in collection.schema.column_order
    end)
  end

end

