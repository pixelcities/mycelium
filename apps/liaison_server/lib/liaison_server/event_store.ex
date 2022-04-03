defmodule LiaisonServer.EventStore do
  use EventStore, otp_app: :liaison_server

  # def init(config) do
  #   {:ok, Keyword.put(config, :schema, "ds1")}
  # end
end
