defmodule LiaisonServerWeb.Auth.Local.UserConfirmationController do
  use LiaisonServerWeb, :controller

  require Logger
  import LiaisonServerWeb.Utils

  alias Landlord.{Accounts, Tenants}
  alias KeyX.TrialAgent

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

  @doc """
  Complete the user creation

  A newly created user is also invited to a trial dataspace.
  """
  def confirm(conn, %{"token" => token}) do
    case Accounts.confirm_user(token) do
      {:ok, user} ->
        # Grab the trial agent config
        config = Application.get_env(:key_x, KeyX.TrialAgent)

        # Invite the user to the trial dataspace
        with ds <- Tenants.get_data_space_by_handle(:ds1),
             trial_user <- Accounts.get_user_by_email(config[:email]),
             _ds <- Tenants.invite_to_data_space(ds, trial_user, user)

        do
          # Share the metadata key
          TrialAgent.share_manifest_key(user, :ds1)

          # TODO: Do not create the user in the ds unless the invite is accepted
          Landlord.create_user(Map.from_struct(user), %{user_id: user.id, ds_id: :ds1})
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
end
