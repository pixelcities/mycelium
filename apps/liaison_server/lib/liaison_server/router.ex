defmodule LiaisonServer.Router do
  use Commanded.Commands.CompositeRouter

  router MetaStore.Router
  router DataStore.Router
  router KeyX.Router
  router Landlord.Router
  router Maestro.Router
  router ContentServer.Router
end
