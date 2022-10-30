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
            access: "internal",
            content: nil,
            widget_id: nil,
            date: nil

  alias ContentServer.Aggregates.Content
  alias Core.Commands.{CreateContent, UpdateContent, DeleteContent}
  alias Core.Events.{ContentCreated, ContentUpdated, ContentDeleted}


  def execute(%Content{id: nil}, %CreateContent{} = content) do
    ContentCreated.new(content, date: NaiveDateTime.utc_now())
  end

  def execute(%Content{} = content, %UpdateContent{} = update)
    when content.workspace == update.workspace
  do
    ContentUpdated.new(update, date: NaiveDateTime.utc_now())
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
      date: created.date
    }
  end

  def apply(%Content{} = content, %ContentUpdated{} = updated) do
    %Content{content |
      content: updated.content,
      date: updated.date
    }
  end

  def apply(%Content{} = content, %ContentDeleted{} = event), do: content

end
