defmodule ContentServer.Aggregates.Page do
  defstruct id: nil,
            workspace: nil,
            access: [],
            key_id: nil,
            content_order: [],
            date: nil

  alias ContentServer.Aggregates.Page
  alias Core.Commands.{CreatePage, UpdatePage, SetPageOrder, DeletePage}
  alias Core.Events.{PageCreated, PageUpdated, PageOrderSet, PageDeleted}


  def execute(%Page{id: nil}, %CreatePage{} = page) do
    PageCreated.new(page, date: NaiveDateTime.utc_now())
  end

  def execute(%Page{} = page, %UpdatePage{} = update)
    when page.workspace == update.workspace
  do
    PageUpdated.new(update, date: NaiveDateTime.utc_now())
  end

  # Only used as a guide for ordering. Content ids not present
  # in this list will be ordered by creation date as a fallback.
  def execute(%Page{} = page, %SetPageOrder{} = update)
    when page.workspace == update.workspace
  do
    PageOrderSet.new(update, date: NaiveDateTime.utc_now())
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

  def apply(%Page{} = page, %PageOrderSet{} = updated) do
    %Page{page |
      content_order: updated.content_order,
      date: updated.date
    }
  end

  def apply(%Page{} = page, %PageDeleted{} = _event), do: page

end
