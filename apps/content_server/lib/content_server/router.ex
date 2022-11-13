defmodule ContentServer.Router do

  use Commanded.Commands.Router

  alias Core.Commands.{
    CreateContent,
    UpdateContent,
    DeleteContent,
    CreatePage,
    UpdatePage,
    DeletePage
  }
  alias ContentServer.Aggregates.{
    Content,
    ContentLifespan,
    Page,
    PageLifespan
  }

  middleware Core.Middleware.TagCommand
  middleware Core.Middleware.EnrichCommand

  identify(Content, by: :id, prefix: "content-")
  identify(Page, by: :id, prefix: "pages-")

  dispatch([ CreateContent, UpdateContent, DeleteContent ],
    to: Content,
    lifespan: ContentLifespan
  )

  dispatch([ CreatePage, UpdatePage, DeletePage ],
    to: Page,
    lifespan: PageLifespan
  )

end
