defimpl Core.Middleware.CommandEnrichment, for: [Core.Commands.UpdateSource, Core.Commands.DeleteSource] do

  alias Core.Commands.{
    UpdateSource,
    DeleteSource
  }

  @doc """
  The aggregates needs to know which user is attempting to execute this command
  """
  def enrich(%UpdateSource{} = command, %{"user_id" => user_id} = _metadata) do
    {:ok, %UpdateSource{command |
      __metadata__: %{
        user_id: user_id
      }
    }}
  end

  def enrich(%DeleteSource{} = command, %{"user_id" => user_id} = metadata) do
    # Collections that are created from sources share the same id, so we can use
    # this id to easily check if any collections are downstream from this source.
    source_has_collection = MetaStore.get_collection!(command.id, tenant: Map.get(metadata, "ds_id")) != nil

    {:ok, %DeleteSource{command |
      __metadata__: %{
        user_id: user_id,
        is_admin: Map.get(metadata, "role") == "owner",
        source_has_collection: source_has_collection
      }
    }}
  end

end

