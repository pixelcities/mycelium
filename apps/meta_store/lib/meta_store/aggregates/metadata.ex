defmodule MetaStore.Aggregates.Metadata do
  defstruct id: nil,
            workspace: nil,
            metadata: nil,
            date: nil

  require Logger

  alias MetaStore.Aggregates.Metadata
  alias Core.Commands.{CreateMetadata, UpdateMetadata}
  alias Core.Events.{MetadataCreated, MetadataUpdated}

  @doc """
  Publish some metadata
  """
  def execute(%Metadata{id: nil}, %CreateMetadata{} = metadata) do
    MetadataCreated.new(metadata, date: NaiveDateTime.utc_now())
  end

  def execute(%Metadata{id: _id}, %CreateMetadata{} = metadata) do
    Logger.warning(
      "Received command to create metadata, but it already exists. " <>
      "Updating existing metadata instead. This is a noop, but may " <>
      "indicate a problem in the client."
    )

    MetadataUpdated.new(metadata, date: NaiveDateTime.utc_now())
  end

  def execute(%Metadata{} = metadata, %UpdateMetadata{} = update)
    when metadata.workspace == update.workspace
  do
    MetadataUpdated.new(update, date: NaiveDateTime.utc_now())
  end


  # State mutators

  def apply(%Metadata{} = metadata, %MetadataCreated{} = event) do
    %Metadata{metadata |
      id: event.id,
      workspace: event.workspace,
      metadata: event.metadata,
      date: event.date
    }
  end

  def apply(%Metadata{} = metadata, %MetadataUpdated{} = event) do
    %Metadata{metadata |
      metadata: event.metadata,
      date: event.date
    }
  end

end
