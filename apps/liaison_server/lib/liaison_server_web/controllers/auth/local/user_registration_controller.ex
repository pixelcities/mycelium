defmodule LiaisonServerWeb.Auth.Local.UserRegistrationController do
  use LiaisonServerWeb, :controller

  import LiaisonServerWeb.Utils

  alias Landlord.Accounts
  alias LiaisonServerWeb.Auth

  plug Hammer.Plug, [
    rate_limit: {"register", 60_000, 1},
  ] when action == :register_user

  def register_user(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        if user.confirmed_at == nil do
          {:ok, _} =
            Accounts.deliver_user_confirmation_instructions(
              user,
              &Routes.user_confirmation_url(get_external_host(), :confirm_registration, &1),
              Map.get(user_params, "join_trial", "false") == "true"
            )
        end

        conn
        |> Auth.log_in_user(user, %{}, user)

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = changeset_error(changeset)

        conn
        |> put_status(400)
        |> json(errors)

      {:error, _} ->
        conn
        |> put_status(401)
        |> json(%{error: "Unauthorized"})
    end
  end
end
