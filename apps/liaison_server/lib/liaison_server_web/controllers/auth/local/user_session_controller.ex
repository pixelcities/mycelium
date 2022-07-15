defmodule LiaisonServerWeb.Auth.Local.UserSessionController do
  use LiaisonServerWeb, :controller

  alias Landlord.Accounts
  alias LiaisonServerWeb.Auth

  plug Hammer.Plug, [
    rate_limit: {"login", 60_000, 5},
  ] when action == :login_user

  def login_user(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      Auth.log_in_user(conn, user, user_params, user)
    else
      conn
      |> put_status(401)
      |> json(%{"error" => "Invalid email or password"})
    end
  end

  def logout_user(conn, _params) do
    conn
    |> Auth.log_out_user()
  end
end
