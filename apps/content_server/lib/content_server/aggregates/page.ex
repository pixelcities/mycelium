defmodule ContentServer.Aggregates.PageLifespan do
  @behaviour Commanded.Aggregates.AggregateLifespan

  alias Core.Events.PageDeleted

  def after_event(%PageDeleted{}), do: :stop
  def after_event(_event), do: :infinity
  def after_command(_command), do: :infinity
  def after_error(_error), do: :stop
end

defmodule ContentServer.Aggregates.Page do
  defstruct id: nil,
            workspace: nil,
            access: [],
            key_id: nil,
            date: nil

  alias ContentServer.Aggregates.Page
  alias Core.Commands.{CreatePage, UpdatePage, DeletePage}
  alias Core.Events.{PageCreated, PageUpdated, PageDeleted}


  def execute(%Page{id: nil}, %CreatePage{} = page) do
    PageCreated.new(page, date: NaiveDateTime.utc_now())
  end

  def execute(%Page{} = page, %UpdatePage{} = update)
    when page.workspace == update.workspace
  do
    PageUpdated.new(update, date: NaiveDateTime.utc_now())
  end

  def execute(%Page{} = _page, %DeletePage{} = command) do
    PageDeleted.new(command, date: NaiveDateTime.utc_now())
  end


  # State mutators

  def apply(%Page{} = page, %PageCreated{} = created) do
    %Page{page |
      id: created.id,
      workspace: created.workspace,
      access: created.access,
      key_id: created.key_id,
      date: created.date
    }
  end

  def apply(%Page{} = page, %PageUpdated{} = updated) do
    %Page{page |
      key_id: updated.key_id,
      date: updated.date
    }
  end

  def apply(%Page{} = page, %PageDeleted{} = event), do: page

end
