defmodule LiaisonServerWeb.Auth.Local.UserRegistrationController do
  use LiaisonServerWeb, :controller

  import LiaisonServerWeb.Utils

  alias Landlord.Accounts
  alias LiaisonServerWeb.Auth

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &Routes.user_confirmation_url(get_external_host(), :confirm, &1)
          )

        conn
        |> Auth.log_in_user(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = changeset_error(changeset)

        json(conn, errors)
    end
  end
end
