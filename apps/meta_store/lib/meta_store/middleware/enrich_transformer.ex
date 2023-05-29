defimpl Core.Middleware.CommandEnrichment, for: [Core.Commands.UpdateTransformer, Core.Commands.UpdateTransformerWAL] do

  alias Core.Commands.{
    UpdateTransformer,
    UpdateTransformerWAL
  }

  # Create an access map for all the identifiers in the WAL
  # TODO: Handle transitive transformers
  def enrich(%UpdateTransformer{id: id, wal: %{"identifiers" => identifiers}} = command, %{"user_id" => user_id, "ds_id" => ds_id} = _metadata) do
    {:ok, %UpdateTransformer{command |
      __metadata__: %{
        access_map: build_access_map(id, identifiers, user_id, ds_id)
      }
    }}
  end

  def enrich(%UpdateTransformerWAL{id: id, wal: %{"identifiers" => identifiers}} = command, %{"user_id" => user_id, "ds_id" => ds_id} = _metadata) do
    {:ok, %UpdateTransformerWAL{command |
      __metadata__: %{
        access_map: build_access_map(id, identifiers, user_id, ds_id)
      }
    }}
  end

  defp build_access_map(transformer_id, identifiers, user_id, ds_id) do
    identifiers
    |> Map.to_list()
    |> Enum.map(fn ({k, %{"id" => id, "type" => type} = v}) ->
      access = case type do
        "table" ->
          case MetaStore.get_collection!(id, tenant: ds_id) do
            nil -> id == transformer_id
            collection ->
              case MetaStore.get_schema!(collection.schema.id, tenant: ds_id) do
                nil -> []
                schema ->
                  Enum.any?(schema.shares, fn share ->
                    share.principal == user_id
                  end)
              end
          end
        "column" ->
          case MetaStore.get_column!(id, tenant: ds_id) do
            nil -> Map.get(v, "action") == "add"
            column ->
              Enum.any?(column.shares, fn share ->
                share.principal == user_id
              end)
          end
      end

      {k, access}
    end)
    |> Enum.into(%{})
  end
end

