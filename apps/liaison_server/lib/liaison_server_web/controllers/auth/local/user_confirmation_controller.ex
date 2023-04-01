defmodule LiaisonServerWeb.Auth.Local.UserConfirmationController do
  use LiaisonServerWeb, :controller

  require Logger
  import LiaisonServerWeb.Utils

  alias Landlord.{Accounts, Tenants}
  alias KeyX.TrialAgent

  def request_confirm_registration(conn, %{"user" => %{"email" => email}}) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &Routes.user_confirmation_url(get_external_host(), :confirm_registration, &1),
        false
      )
    end

    conn
    |> redirect(to: "/")
  end

  @doc """
  Complete the user creation

  A newly created user is also invited to a trial dataspace if they requested that as
  part of the original registration. The trial dataspace invite is special in that most
  user information will be redacted.
  """
  def confirm_registration(conn, %{"token" => token}) do
    case Accounts.confirm_user(token) do
      {:ok, {user, join_trial?}} ->
        if join_trial? do
          # Grab the trial agent config
          config = Application.get_env(:key_x, KeyX.TrialAgent)

          # Add the user directly to the trial dataspace
          with ds <- Tenants.get_data_space_by_handle(:trial),
               _trial_user <- Accounts.get_user_by_email(config[:email]),
               _ds <- Tenants.add_user_to_data_space(ds, user)

          do
            # Share the metadata key
            TrialAgent.share_manifest_key(user, :trial)

            # Add the new user with a randomized name
            Landlord.create_user(%{
              id: user.id,
              name: random_name(),
              email: "[REDACTED]",
              role: "collaborator"
            }, %{"user_id" => user.id, "ds_id" => :trial})
          end
        end

        json(conn, %{status: "ok"})

      :error ->
        case conn.assigns do
          %{current_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            conn
            |> put_status(409)
            |> json(%{error: "user already confirmed"})

          %{} ->
            conn
            |> put_status(401)
            |> json(%{error: "user confirmation link is invalid or it has expired"})
        end
    end
  end

  defp random_name() do
    "user#{Enum.random(100_000..999_999)}"
  end

end
