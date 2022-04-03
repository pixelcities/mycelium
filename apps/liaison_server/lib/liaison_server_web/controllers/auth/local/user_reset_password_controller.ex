defmodule LiaisonServerWeb.Auth.Local.UserResetPasswordController do
  use LiaisonServerWeb, :controller

  import LiaisonServerWeb.Utils

  alias Landlord.Accounts

  plug :get_user_by_reset_password_token when action in [:edit, :update]

  def create(conn, %{"user" => %{"email" => email}}) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &Routes.user_reset_password_url(get_external_host(), :update, &1)
      )
    end

    json(conn, %{
      "status" => "ok",
      "info" => "If your email is in our system, you will receive instructions to reset your password shortly"
    })
  end

  def update(conn, %{"user" => user_params}) do
    case Accounts.reset_user_password(conn.assigns.user, user_params) do
      {:ok, _} ->
        json(conn, %{
          "status" => "ok",
          "info" => "Password reset successfully"
        })

      {:error, changeset} ->
        json(conn, changeset_error(changeset))
    end
  end

  defp get_user_by_reset_password_token(conn, _opts) do
    %{"token" => token} = conn.params

    if user = Accounts.get_user_by_reset_password_token(token) do
      conn |> assign(:user, user) |> assign(:token, token)
    else
      conn
      |> redirect(to: "/")
      |> halt()
    end
  end
end
