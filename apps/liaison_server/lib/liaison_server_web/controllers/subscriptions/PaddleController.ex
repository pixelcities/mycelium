defmodule LiaisonServerWeb.Subscriptions.PaddleController do
  use LiaisonServerWeb, :controller

  alias Landlord.Tenants

  require Logger

  plug :verify_signature

  def webhook(conn, params) do
    IO.puts("Received webhook:")
    IO.inspect(params)

    case Tenants.manage_subscription(params) do
      :ok -> json(conn, "")
      {:error, error} ->
        Logger.error("Error processing Paddle webhook: #{inspect(error)}")

        conn |> send_resp(400, "") |> halt
    end
  end

  @paddle_public_key File.read!("priv/paddle.pub")
    |> :public_key.pem_decode()
    |> hd()
    |> :public_key.pem_entry_decode()

  def verify_signature(conn, _opts) do
    signature = Base.decode64!(conn.params["p_signature"])

    # https://developer.paddle.com/webhook-reference/verifying-webhooks
    data =
      Map.delete(conn.params, "p_signature")
      |> Enum.map(fn {key, val} -> {key, "#{val}"} end)
      |> List.keysort(0)
      |> PhpSerializer.serialize()

    if :public_key.verify(data, :sha, signature, @paddle_public_key) do
      conn
    else
      send_resp(conn, 403, "") |> halt
    end
  end
end
