defmodule MetaStore.Aggregates.TransformerLifespan do
  @behaviour Commanded.Aggregates.AggregateLifespan

  alias Core.Events.TransformerDeleted

  def after_event(%TransformerDeleted{}), do: :stop
  def after_event(_event), do: :infinity
  def after_command(_command), do: :infinity
  def after_error(_error), do: :stop
end

defmodule MetaStore.Aggregates.Transformer do
  defstruct id: nil,
            workspace: nil,
            type: nil,
            targets: [],
            position: [],
            color: "#000000",
            is_ready: false,
            collections: [],
            transformers: [],
            date: nil,
            wal: nil,
            error: nil

  alias MetaStore.Aggregates.Transformer
  alias Core.Commands.{
    CreateTransformer,
    UpdateTransformer,
    SetTransformerPosition,
    AddTransformerTarget,
    RemoveTransformerTarget,
    AddTransformerInput,
    UpdateTransformerWAL,
    SetTransformerIsReady,
    SetTransformerError,
    DeleteTransformer
  }
  alias Core.Events.{
    TransformerCreated,
    TransformerUpdated,
    TransformerPositionSet,
    TransformerTargetAdded,
    TransformerTargetRemoved,
    TransformerInputAdded,
    TransformerWALUpdated,
    TransformerIsReadySet,
    TransformerErrorSet,
    TransformerDeleted
  }

  def execute(%Transformer{id: nil}, %CreateTransformer{} = transformer)
    when transformer.wal == nil
  do
    TransformerCreated.new(transformer,
      is_ready: true,
      date: NaiveDateTime.utc_now()
    )
  end

  def execute(%Transformer{id: id, type: type} = transformer, %UpdateTransformer{__metadata__: %{access_map: access_map}} = update)
    when transformer.workspace == update.workspace
  do
    with :ok <- validate_wal_inputs(id, update.wal, transformer.collections, transformer.transformers),
         :ok <- validate_wal_changes(transformer.wal, update.wal, access_map, type)
    do
      TransformerUpdated.new(update, date: NaiveDateTime.utc_now())
    else
      err -> err
    end
  end

  def execute(%Transformer{} = _transformer, %SetTransformerPosition{} = position) do
    TransformerPositionSet.new(position, date: NaiveDateTime.utc_now())
  end

  def execute(%Transformer{} = transformer, %AddTransformerTarget{} = command) do
    TransformerTargetAdded.new(%{
      id: transformer.id,
      workspace: transformer.workspace,
      target: command.target,
      date: NaiveDateTime.utc_now()
    })
  end

  def execute(%Transformer{} = transformer, %RemoveTransformerTarget{} = command) do
    if Enum.any?(Enum.map(transformer.targets, fn target -> target == command.target end)) do
      TransformerTargetRemoved.new(command, date: NaiveDateTime.utc_now())
    else
      {:error, :no_such_target}
    end
  end

  def execute(%Transformer{} = transformer, %AddTransformerInput{} = command) do
    if transformer.type == "merge" do
      if command.collection != nil and length(transformer.collections) <= 1 do
        TransformerInputAdded.new(%{
          id: transformer.id,
          workspace: transformer.workspace,
          collection: command.collection,
          date: NaiveDateTime.utc_now()
        })
      else
        {:error, :merge_transformer_must_have_up_to_two_collections}
      end

    else
      if length(transformer.collections) == 0 and length(transformer.transformers) == 0 do
        TransformerInputAdded.new(%{
          id: transformer.id,
          workspace: transformer.workspace,
          collection: command.collection,
          transformer: command.transformer,
          date: NaiveDateTime.utc_now()
        })
      else
        {:error, :transformer_already_has_input}
      end
    end
  end

  def execute(%Transformer{id: id, type: type} = transformer, %UpdateTransformerWAL{__metadata__: %{access_map: access_map}} = update)
    when transformer.workspace == update.workspace
  do
    with :ok <- validate_wal_inputs(id, update.wal, transformer.collections, transformer.transformers),
         :ok <- validate_wal_changes(transformer.wal, update.wal, access_map, type)
    do
      TransformerWALUpdated.new(update, date: NaiveDateTime.utc_now())
    end
  end

  def execute(%Transformer{} = _transformer, %SetTransformerIsReady{} = command) do
    TransformerIsReadySet.new(command, date: NaiveDateTime.utc_now())
  end

  def execute(%Transformer{} = _transformer, %SetTransformerError{} = command) do
    TransformerErrorSet.new(command, date: NaiveDateTime.utc_now())
  end

  def execute(%Transformer{} = _transformer, %DeleteTransformer{} = command) do
    TransformerDeleted.new(command, date: NaiveDateTime.utc_now())
  end

  defp validate_wal_inputs(id, wal, collections, transformers) do
    table_identifiers =
      Map.get(wal, "identifiers")
      |> Map.filter(fn {_k, v} -> Map.get(v, "type") == "table" end)
      |> Map.values()
      |> Enum.map(fn x -> Map.get(x, "id") end)
      |> Enum.map(fn x -> x == id || x in collections || x in transformers end)

    if Enum.all?(table_identifiers) do
      :ok
    else
      {:error, :missing_input}
    end
  end

  # Validate access for the WAL changes
  #
  # TODO: Validate strict query structure per transformer type, with the exception
  # of the custom transformer.
  defp validate_wal_changes(original_wal, command_wal, access_map, type) do
    original_identifers = Map.to_list(Map.get(original_wal || %{}, "identifiers", %{}))
    command_identifiers = Map.to_list(Map.get(command_wal || %{}, "identifiers", %{}))

    # Only validate new identifiers, the user may not have access to existing ones, which
    # is perfectly allowed as long as they don't change anything.
    new_identifiers = MapSet.difference(MapSet.new(command_identifiers), MapSet.new(original_identifers))
    access_to_identifiers =
      new_identifiers
      |> MapSet.to_list()
      |> Enum.reject(fn {_k, v} -> Map.get(v, "action") == "drop" end)
      |> Enum.map(fn {k, _v} -> Map.get(access_map, k) end)
      |> Enum.all?()

    if access_to_identifiers || type == "mpc" do
      original_transactions = Map.get(original_wal || %{}, "transactions", [])
      command_transactions = Map.get(command_wal || %{}, "transactions", [])

      # Next, ensure that unauthorized identifiers were not used in the transaction
      new_transactions = MapSet.difference(MapSet.new(command_transactions), MapSet.new(original_transactions))
      access_to_refs =
        new_transactions
        |> MapSet.to_list()
        |> Enum.map(fn transaction ->
          case Regex.scan(~r/%([0-9]+)\$I/, transaction) do
            nil -> false
            match -> Enum.all?(Enum.map(match, fn [_, id] -> Map.get(access_map, id) end))
          end
        end)
        |> Enum.all?()

      if access_to_refs do
        :ok
      else
        {:error, :invalid_reference_in_transaction}
      end
    else
      {:error, :new_identifier_unauthorized}
    end
  end

  # State mutators

  def apply(%Transformer{} = transformer, %TransformerCreated{} = created) do
    %Transformer{transformer |
      id: created.id,
      workspace: created.workspace,
      type: created.type,
      targets: created.targets,
      position: created.position,
      color: created.color,
      is_ready: created.is_ready,
      collections: created.collections,
      transformers: created.transformers,
      date: created.date
    }
  end

  def apply(%Transformer{} = transformer, %TransformerUpdated{} = updated) do
    %Transformer{transformer |
      is_ready: updated.is_ready,
      date: updated.date
    }
  end

  def apply(%Transformer{} = transformer, %TransformerPositionSet{} = event) do
    %Transformer{transformer |
      position: event.position,
      date: event.date
    }
  end

  def apply(%Transformer{} = transformer, %TransformerTargetAdded{} = event) do
    %Transformer{transformer |
      targets: transformer.targets ++ [event.target],
      date: event.date
    }
  end

  def apply(%Transformer{} = transformer, %TransformerTargetRemoved{} = event) do
    %Transformer{transformer |
      targets: Enum.reject(transformer.targets, fn target -> target == event.target end),
      date: event.date
    }
  end

  def apply(%Transformer{} = transformer, %TransformerInputAdded{} = event) do
    if event.collection do
      %Transformer{transformer |
        collections: transformer.collections ++ [event.collection],
        date: event.date
      }
    else
      %Transformer{transformer |
        transformers: transformer.transformers ++ [event.transformer],
        date: event.date
      }
    end
  end

  def apply(%Transformer{} = transformer, %TransformerWALUpdated{} = updated) do
    %Transformer{transformer |
      wal: updated.wal,
      date: updated.date
    }
  end

  def apply(%Transformer{} = transformer, %TransformerIsReadySet{} = updated) do
    %Transformer{transformer |
      is_ready: updated.is_ready,
      date: updated.date
    }
  end

  def apply(%Transformer{} = transformer, %TransformerErrorSet{} = updated) do
    %Transformer{transformer |
      error: (if updated.is_error, do: Map.get(updated, :error, ""), else: nil),
      date: updated.date
    }
  end

  def apply(%Transformer{} = transformer, %TransformerDeleted{} = _event), do: transformer

end
