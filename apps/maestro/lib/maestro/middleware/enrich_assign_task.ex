defimpl Core.Middleware.CommandEnrichment, for: Core.Commands.AssignTask do

  alias Core.Commands.AssignTask

  @doc """
  Enrich transformer task commands with the right fragments for this user
  """
  def enrich(%AssignTask{} = command, metadata) do
    ds_id = Map.get(metadata, "ds_id")

    # Only implemented for transformer tasks
    if command.type == "transformer" do
      transformer_id = Map.get(command.task, "transformer_id")
      user_id = command.worker

      case lookup_owned_fragments(transformer_id, user_id, ds_id) do
        {:ok, fragments} ->
          {:ok, Map.put(command, :fragments, fragments)}
        {:error, error} -> {:error, error}
      end

    else
      {:ok, command}
    end
  end

  defp lookup_owned_fragments(transformer_id, user_id, ds_id) do
    user = Landlord.Accounts.get_user!(user_id)
    transformer = MetaStore.get_transformer!(transformer_id, tenant: ds_id)

    # TODO: handle transitive transformers
    fragments = Enum.map(transformer.collections, fn collection_id ->
      collection = MetaStore.get_collection!(collection_id, tenant: ds_id)
      schema = MetaStore.get_schema!(collection.schema.id, tenant: ds_id)

      get_fragments_by_schema(schema, user.id, ds_id)
    end)

    # Concat the owned fragments from each schema
    case Enum.reduce_while(fragments, {:ok, []}, fn {left, right}, {:ok, acc} ->
      if left == :ok, do: {:cont, {:ok, Enum.concat(acc, right)}}, else: {:halt, {:error, right}}
    end) do
      {:ok, owned_fragments} ->
        # Collect column identifiers required for the transaction by filtering out collections / transformers
        identifiers = Enum.filter(Map.values(Map.get(transformer.wal, "identifiers")), fn i ->
          (i != transformer_id) and (i not in transformer.collections) and (i not in transformer.transformers)
        end)

        # If there are transaction identifers that are not owned, we cannot guarantee that the entire transaction
        # can be run. Better to strip out all fragments related to the transaction and have another worker handle it.
        if Enum.any?(identifiers, fn i -> i not in owned_fragments end) do
          {:ok, Enum.reject(owned_fragments, fn f -> f in identifiers end)}
        else
          {:ok, owned_fragments}
        end

      {:error, error} -> {:error, error}
    end
  end

  defp get_fragments_by_schema(schema, user_id, ds_id) do
    if Enum.any?(schema.shares, fn share -> share.principal == user_id end) do
      fragments = Enum.filter(schema.columns, fn c ->
        column = if match?(%Ecto.Association.NotLoaded{}, c.shares), do: MetaStore.get_column!(c.id, tenant: ds_id), else: c

        Enum.any?(column.shares, fn share -> share.principal == user_id end)
      end)

      {:ok, Enum.map(fragments, fn fragment -> fragment.id end)}
    else
      {:error, :user_cannot_read_schema}
    end
  end

end
