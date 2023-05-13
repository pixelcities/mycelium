defmodule LiaisonServerWeb.Subscriptions.SubscriptionController do
  use LiaisonServerWeb, :controller

  alias Landlord.Tenants

  require Logger

  def get_subscription(conn, %{"handle" => handle}) do
    user = conn.assigns.current_user

    with {:ok, data_space} <- Tenants.get_data_space_by_user_and_handle(user, handle, unsafe: true),
         true <- Tenants.is_owner?(data_space, user),
         subscription <- Tenants.get_subscription(data_space)
    do
      json(conn, subscription)

    else
      err ->
        Logger.error(Exception.format(:error, err))
        conn |> put_status(404) |> json(%{"status" => "not found"})
    end
  end
end
