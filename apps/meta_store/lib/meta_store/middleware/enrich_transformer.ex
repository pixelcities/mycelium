defimpl Core.Middleware.CommandEnrichment, for: [Core.Commands.UpdateTransformer, Core.Commands.UpdateTransformerWAL] do

  alias Core.Commands.{
    UpdateTransformer,
    UpdateTransformerWAL
  }

  # Create an access map for all the identifiers in the WAL
  # TODO: Handle transitive transformers
  def enrich(%UpdateTransformer{wal: %{"identifiers" => identifiers}} = command, %{"user_id" => user_id, "ds_id" => ds_id} = _metadata) do
    {:ok, %UpdateTransformer{command |
      __metadata__: %{
        access_map: build_access_map(identifiers, user_id, ds_id)
      }
    }}
  end

  def enrich(%UpdateTransformerWAL{wal: %{"identifiers" => identifiers}} = command, %{"user_id" => user_id, "ds_id" => ds_id} = _metadata) do
    {:ok, %UpdateTransformerWAL{command |
      __metadata__: %{
        access_map: build_access_map(identifiers, user_id, ds_id)
      }
    }}
  end

  defp build_access_map(identifiers, user_id, ds_id) do
    identifiers
    |> Map.to_list()
    |> Enum.filter(fn ({_k, v}) -> Map.get(v, "action") != "add" end)
    |> Enum.map(fn ({k, %{"id" => id, "type" => type}}) ->
      access = case type do
        "table" ->
          case MetaStore.get_collection!(id, tenant: ds_id) do
            nil -> false
            collection ->
              Enum.any?(collection.schema.shares, fn share ->
                share.principal == user_id
              end)
          end
        "column" ->
          case MetaStore.get_column!(id, tenant: ds_id) do
            nil -> false
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

