defimpl Core.Middleware.CommandEnrichment, for: [Core.Commands.UpdateCollection, Core.Commands.UpdateCollectionSchema, Core.Commands.DeleteCollection] do

  alias Core.Commands.{
    UpdateCollection,
    UpdateCollectionSchema,
    DeleteCollection
  }

  def enrich(%UpdateCollection{} = command, %{"user_id" => user_id} = _metadata) do
    {:ok, %UpdateCollection{command |
      __metadata__: %{
        user_id: user_id
      }
    }}
  end

  def enrich(%UpdateCollectionSchema{} = command, %{"user_id" => user_id} = _metadata) do
    {:ok, %UpdateCollectionSchema{command |
      __metadata__: %{
        user_id: user_id
      }
    }}
  end

  def enrich(%DeleteCollection{} = command, %{"user_id" => user_id} = metadata) do
    {:ok, %DeleteCollection{command |
      __metadata__: %{
        user_id: user_id,
        is_admin: Map.get(metadata, "role") == "owner"
      }
    }}
  end
end
