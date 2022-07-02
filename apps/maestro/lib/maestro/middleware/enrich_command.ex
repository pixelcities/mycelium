defimpl Core.Middleware.CommandEnrichment, for: Core.Commands.AssignTask do

  alias Core.Commands.AssignTask

  @doc """
  Enrich transformer task commands with the right fragments for this user
  """
  def enrich(%AssignTask{} = command) do
    # Only implemented for transformer tasks
    if command.type == "transformer" do
      transformer_id = Map.get(command.task, "transformer_id")
      user_id = command.worker

      case lookup_owned_fragments(transformer_id, user_id) do
        {:ok, fragments} ->
          {:ok, Map.put(command, :fragments, fragments)}
        {:error, error} -> {:error, error}
      end

    else
      {:ok, command}
    end
  end

  defp lookup_owned_fragments(transformer_id, user_id) do
    user = Landlord.Accounts.get_user!(user_id)
    transformer = MetaStore.get_transformer!(transformer_id)

    # TODO: handle multiple collections and transitive transformers
    collection_id = hd(transformer.collections)

    collection = MetaStore.get_collection!(collection_id)
    schema = MetaStore.get_schema!(collection.schema.id)

    if Enum.any?(schema.shares, fn share -> share.principal == user.email end) do
      fragments = Enum.filter(schema.columns, fn c ->
        column = MetaStore.get_column!(c.id)

        Enum.any?(column.shares, fn share -> share.principal == user.email end)
      end)

      {:ok, Enum.map(fragments, fn fragment -> fragment.id end)}
    else
      {:error, :user_cannot_read_schema}
    end
  end
end
