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

  @doc """
  Create a new transformer
  """
  def execute(%Transformer{id: nil}, %CreateTransformer{} = transformer) do
    TransformerCreated.new(transformer,
      is_ready: true,
      date: NaiveDateTime.utc_now()
    )
  end

  def execute(%Transformer{} = transformer, %UpdateTransformer{} = update)
    when transformer.workspace == update.workspace
  do
    TransformerUpdated.new(update, date: NaiveDateTime.utc_now())
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

  def execute(%Transformer{} = transformer, %UpdateTransformerWAL{} = update)
    when transformer.workspace == update.workspace
  do
    TransformerWALUpdated.new(update, date: NaiveDateTime.utc_now())
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
      targets: Enum.filter(transformer.targets, fn target -> target == event.target end),
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

  def apply(%Transformer{} = transformer, %TransformerDeleted{} = event), do: transformer

end
