defmodule LiaisonServerWeb.Presence do
  use Phoenix.Presence,
    otp_app: :liaison_server,
    pubsub_server: LiaisonServer.PubSub
end

