defimpl Core.Middleware.CommandEnrichment, for: Core.Commands.AssignTask do

  import Maestro.Utils

  alias Core.Commands.AssignTask

  @doc """
  Enrich transformer task commands with the right fragments for this user
  """
  def enrich(%AssignTask{} = command, %{"ds_id" => ds_id} = _metadata) do
    case command.type do
      "transformer" ->
        transformer_id = Map.get(command.task, "transformer_id")
        user_id = command.worker

        case lookup_owned_transformer_fragments(transformer_id, user_id, ds_id) do
          {:ok, fragments} -> {:ok, Map.put(command, :fragments, fragments)}
          {:error, error} -> {:error, error}
        end

      "widget" -> {:ok, command}
        widget_id = Map.get(command.task, "widget_id")
        user_id = command.worker

        case lookup_owned_widget_fragments(widget_id, user_id, ds_id) do
          {:ok, fragments} ->
            {:ok, Map.put(command, :fragments, fragments)}
          {:error, error} -> {:error, error}
        end

      _ -> {:ok, command}
    end
  end

  defp lookup_owned_transformer_fragments(transformer_id, user_id, ds_id) do
    transformer = MetaStore.get_transformer!(transformer_id, tenant: ds_id)

    if (transformer != nil) do
      # TODO: handle transitive transformers
      fragments = Enum.map(transformer.collections, fn collection_id ->
        collection = MetaStore.get_collection!(collection_id, tenant: ds_id)
        schema = MetaStore.get_schema!(collection.schema.id, tenant: ds_id)

        get_fragments_by_schema(schema, user_id, ds_id)
      end)

      # Collect column identifiers required for the transaction by filtering out collections / transformers
      identifiers =
        get_transformer_identifiers(transformer)
        |> Enum.reject(fn identifier -> Map.get(identifier, "action") == "drop" end) # Drop doesn't require a query
        |> Enum.map(fn identifier -> Map.get(identifier, "id") end)

      validate_owned_fragments(fragments, identifiers, transformer.type)
    else
      {:error, :task_outdated}
    end
  end

  defp lookup_owned_widget_fragments(widget_id, user_id, ds_id) do
    widget = MetaStore.get_widget!(widget_id, tenant: ds_id)

    if (widget != nil) do
      collection = MetaStore.get_collection!(widget.collection, tenant: ds_id)
      schema = MetaStore.get_schema!(collection.schema.id, tenant: ds_id)

      fragments = get_fragments_by_schema(schema, user_id, ds_id)
      identifiers =
        get_widget_identifiers(widget)
        |> Enum.map(fn identifier -> Map.get(identifier, "id") end)

      validate_owned_fragments([fragments], identifiers, "widget")
    else
      {:error, :task_outdated}
    end
  end

  defp validate_owned_fragments(fragments, identifiers, type) do
    # Concat the owned fragments from each schema
    case Enum.reduce_while(fragments, {:ok, []}, fn {left, right}, {:ok, acc} ->
      if left == :ok, do: {:cont, {:ok, Enum.concat(acc, right)}}, else: {:halt, {:error, right}}
    end) do
      {:ok, owned_fragments} ->
        # If there are identifiers that are not owned, we cannot guarantee that the entire task can be run.
        # Better to strip out all fragments related to the identifiers and have another worker handle it.
        if type != "mpc" && Enum.any?(identifiers, fn i -> i not in owned_fragments end) do
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
