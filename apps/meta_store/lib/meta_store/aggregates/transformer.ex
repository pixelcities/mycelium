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
            wal: nil

  alias MetaStore.Aggregates.Transformer
  alias Core.Commands.{CreateTransformer, UpdateTransformer, SetTransformerPosition, AddTransformerTarget, AddTransformerInput, UpdateTransformerWAL}
  alias Core.Events.{TransformerCreated, TransformerUpdated, TransformerPositionSet, TransformerTargetAdded, TransformerInputAdded, TransformerWALUpdated}

  @doc """
  Create a new transformer
  """
  def execute(%Transformer{id: nil}, %CreateTransformer{} = transformer) do
    TransformerCreated.new(transformer, date: NaiveDateTime.utc_now())
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

end
