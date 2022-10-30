defmodule ContentServer.Router do

  use Commanded.Commands.Router

  alias Core.Commands.{
    CreateContent,
    UpdateContent,
    DeleteContent
  }
  alias ContentServer.Aggregates.{
    Content,
    ContentLifespan
  }

  middleware Core.Middleware.TagCommand
  middleware Core.Middleware.EnrichCommand

  identify(Content, by: :id, prefix: "content-")

  dispatch([ CreateContent, UpdateContent, DeleteContent ],
    to: Content,
    lifespan: ContentLifespan
  )

end
