defimpl Core.Middleware.CommandEnrichment, for: [Core.Commands.UpdateSource, Core.Commands.UpdateSourceURI, Core.Commands.UpdateSourceSchema, Core.Commands.DeleteSource] do

  alias Core.Commands.{
    UpdateSource,
    UpdateSourceURI,
    UpdateSourceSchema,
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

  def enrich(%UpdateSourceSchema{} = command, metadata) do
    user_id = Map.get(metadata, "user_id")

    {:ok, %UpdateSourceSchema{command |
      __metadata__: %{
        user_id: user_id,
        is_internal: is_nil(user_id)
      }
    }}
  end

  def enrich(%UpdateSourceURI{} = command, %{"user_id" => user_id} = _metadata) do
    {:ok, %UpdateSourceURI{command |
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

