defimpl Core.Middleware.CommandEnrichment, for: Core.Commands.DeleteSource do

  alias Core.Commands.DeleteSource

  @doc """
  The aggregates needs to know if this source has a collection
  """
  def enrich(%DeleteSource{} = command, %{"user_id" => user_id} = metadata) do
    # Collections that are created from sources share the same id, so we can use
    # this id to easily check if any collections are downstream from this source.
    source_has_collection = MetaStore.get_collection!(command.id, tenant: Map.get(metadata, "ds_id")) != nil

    {:ok, %{command |
      __metadata__: %{
        user_id: user_id,
        source_has_collection: source_has_collection
      }
    }}
  end
end
