defimpl Core.Middleware.CommandEnrichment, for: [Core.Commands.PutWidgetSetting, Core.Commands.DeleteWidget] do

  alias Core.Commands.{
    PutWidgetSetting,
    DeleteWidget
  }

  def enrich(%PutWidgetSetting{} = command, %{"user_id" => user_id, "ds_id" => ds_id} = _metadata) do
    shares = if String.contains?(String.downcase(command.key, :ascii), "column") do
      case MetaStore.get_column!(command.value, tenant: ds_id) do
        nil -> []
        column -> column.shares
      end
    else
      []
    end

    {:ok, %PutWidgetSetting{command |
      __metadata__: %{
        user_id: user_id,
        shares: shares
      }
    }}
  end

  def enrich(%DeleteWidget{} = command, %{"user_id" => user_id, "ds_id" => ds_id} = metadata) do
    shares =
      case MetaStore.get_widget!(command.id, tenant: ds_id) do
        nil -> []
        widget ->
          case MetaStore.get_collection!(widget.collection, tenant: ds_id) do
            nil -> []
            collection -> collection.schema.shares
          end
      end

    {:ok, %DeleteWidget{command |
      __metadata__: %{
        user_id: user_id,
        is_admin: Map.get(metadata, "role") == "owner",
        shares: shares
      }
    }}
  end

end

