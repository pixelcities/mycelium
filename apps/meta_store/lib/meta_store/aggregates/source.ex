defmodule MetaStore.Aggregates.Source do
  defstruct id: nil,
            workspace: nil,
            type: nil,
            uri: nil,
            schema: nil,
            is_published: false,
            date: nil

  alias MetaStore.Aggregates.Source
  alias Core.Commands.{CreateSource, UpdateSource}
  alias Core.Events.{SourceCreated, SourceUpdated}

  @doc """
  Publish a source
  """
  def execute(%Source{id: nil}, %CreateSource{} = source) do
    SourceCreated.new(source, date: NaiveDateTime.utc_now())
  end

  def execute(%Source{} = source, %UpdateSource{} = update)
    when source.workspace == update.workspace
  do
    SourceUpdated.new(update, date: NaiveDateTime.utc_now())
  end


  # State mutators

  def apply(%Source{} = source, %SourceCreated{} = created) do
    %Source{source |
      id: created.id,
      workspace: created.workspace,
      uri: created.uri,
      type: created.type,
      schema: created.schema,
      is_published: created.is_published,
      date: created.date
    }
  end

  def apply(%Source{} = source, %SourceUpdated{} = updated) do
    %Source{source |
      schema: updated.schema,
      is_published: updated.is_published,
      date: updated.date
    }
  end

end
