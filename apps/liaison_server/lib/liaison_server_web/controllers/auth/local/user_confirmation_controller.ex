defmodule LiaisonServerWeb.Auth.Local.UserConfirmationController do
  use LiaisonServerWeb, :controller

  import LiaisonServerWeb.Utils

  alias Landlord.Accounts

  def create(conn, %{"user" => %{"email" => email}}) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &Routes.user_confirmation_url(get_external_host(), :confirm, &1)
      )
    end

    conn
    |> redirect(to: "/")
  end

  def confirm(conn, %{"token" => token}) do
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        json(conn, %{"status": "ok"})

      :error ->
        case conn.assigns do
          %{current_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            conn
            |> put_status(409)
            |> json(%{"error": "user already confirmed"})

          %{} ->
            conn
            |> put_status(401)
            |> json(%{"error": "user confirmation link is invalid or it has expired"})
        end
    end
  end
end
