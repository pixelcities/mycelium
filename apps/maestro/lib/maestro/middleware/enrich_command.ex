defimpl Core.Middleware.CommandEnrichment, for: Core.Commands.AssignTask do

  alias Core.Commands.AssignTask

  @doc """
  Enrich transformer task commands with the right fragments for this user
  """
  def enrich(%AssignTask{} = command) do
    # Only implemented for transformer tasks
    if command.type == "transformer" do
      collection_id = Map.get(command.task, "collection_id")
      user_id = command.worker

      case lookup_owned_fragments(collection_id, user_id) do
        {:ok, fragments} ->
          AssignTask.new(Map.put(command, :fragments, fragments))
        {:error, error} -> {:error, error}
      end

    else
      {:ok, command}
    end
  end

  defp lookup_owned_fragments(collection_id, user_id) do
    user = Landlord.Accounts.get_user!(user_id)
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
