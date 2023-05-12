defmodule ContentServer.Aggregates.ContentLifespan do
  @behaviour Commanded.Aggregates.AggregateLifespan

  alias Core.Events.ContentDeleted

  def after_event(%ContentDeleted{}), do: :stop
  def after_event(_event), do: :infinity
  def after_command(_command), do: :infinity
  def after_error(_error), do: :stop
end

defmodule ContentServer.Aggregates.Content do
  defstruct id: nil,
            workspace: nil,
            type: nil,
            access: [],
            content: nil,
            draft: nil,
            widget_id: nil,
            height: nil,
            date: nil

  alias ContentServer.Aggregates.Content
  alias Core.Commands.{CreateContent, UpdateContent, UpdateContentDraft, DeleteContent}
  alias Core.Events.{ContentCreated, ContentUpdated, ContentDraftUpdated, ContentDeleted}


  # TODO: validate type consistency
  def execute(%Content{id: nil}, %CreateContent{} = content) do
    ContentCreated.new(content, date: NaiveDateTime.utc_now())
  end

  def execute(%Content{} = content, %UpdateContent{} = update)
    when content.workspace == update.workspace
  do
    ContentUpdated.new(update, date: NaiveDateTime.utc_now())
  end

  def execute(%Content{} = content, %UpdateContentDraft{} = update)
    when content.workspace == update.workspace
  do
    ContentDraftUpdated.new(update, date: NaiveDateTime.utc_now())
  end

  def execute(%Content{} = _content, %DeleteContent{} = command) do
    ContentDeleted.new(command, date: NaiveDateTime.utc_now())
  end


  # State mutators

  def apply(%Content{} = content, %ContentCreated{} = created) do
    %Content{content |
      id: created.id,
      workspace: created.workspace,
      type: created.type,
      access: created.access,
      widget_id: created.widget_id,
      content: created.content,
      draft: created.draft,
      height: created.height,
      date: created.date
    }
  end

  def apply(%Content{} = content, %ContentUpdated{} = updated) do
    %Content{content |
      content: updated.content,
      draft: updated.draft,
      height: updated.height,
      date: updated.date
    }
  end

  def apply(%Content{} = content, %ContentDraftUpdated{} = updated) do
    %Content{content |
      draft: updated.draft,
      date: updated.date
    }
  end

  def apply(%Content{} = content, %ContentDeleted{} = _event), do: content

end
