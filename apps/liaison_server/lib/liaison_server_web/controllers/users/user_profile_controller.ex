defmodule LiaisonServerWeb.Users.UserProfileController do
  use LiaisonServerWeb, :controller

  import LiaisonServerWeb.Utils

  alias Landlord.{Accounts, Tenants}
  alias KeyX.KeyStore
  alias LiaisonServerWeb.Auth

  plug :assign_email_and_password_changesets

  @doc """
  Just returns the current user struct atm
  """
  def get_user(conn, %{"id" => "me"}) do
    user = conn.assigns.current_user

    conn
    |> Auth.write_csrf_token()
    |> json(user)
  end

  @doc """
  Get a session token to be used with websockets
  """
  def token(conn, _params) do
    user = conn.assigns.current_user

    json(conn, %{
      "user_id" => user.id,
      "token" => Phoenix.Token.sign(conn, "auth", user.id)
    })
  end

  @doc """
  Get a set of session tokens to interact with remote datasets
  """
  def datatokens(conn, %{"uri" => uri, "tag" => tag, "mode" => mode}) do
    user = conn.assigns.current_user
    remote_ip = to_string(:inet_parse.ntoa(conn.remote_ip))

    case DataStore.generate_data_tokens(uri, tag, mode, user, remote_ip) do
      {:ok, tokens} ->
        json(conn, tokens)

      {:error, error} ->
        conn
        |> put_status(401)
        |> json(%{:error => error})
    end
  end

  def update_user(conn, %{"action" => "update_profile"} = params) do
    %{"user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.update_user_profile(user, user_params) do
      {:ok, user} ->
        Enum.each(Tenants.get_data_spaces_by_user(user), fn ds ->
          {:ok, ds_id} = Tenants.to_atom(user, ds.handle)

          Landlord.update_user(Map.from_struct(user), %{"user_id" => user.id, "ds_id" => ds_id})
        end)

        json(conn, %{
          "status" => "ok"
        })

      {:error, changeset} ->
        conn
        |> put_status(400)
        |> json(changeset_error(changeset))
    end
  end


  def update_user(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "user" => user_params, "rotation_token" => rotation_token} = params
    user = conn.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_update_email_instructions(
          applied_user,
          user.email,
          &Routes.user_profile_url(get_external_host(), :confirm_email, &1, rotation_token)
        )

        json(conn, %{
          "status" => "ok",
          "info" => "A link to confirm your email change has been sent to the new address"
        })

      {:error, changeset} ->
        conn
        |> put_status(400)
        |> json(changeset_error(changeset))
    end
  end

  def update_user(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "user" => user_params, "rotation_token" => rotation_token} = params
    user = conn.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->

        # Now that the password has really been updated, also rotate any pending keys
        case KeyStore.commit_rotation(rotation_token, user) do
          {:ok, _} ->
            resp = %{
              "status" => "ok",
              "info" => "Password updated successfully"
            }

            conn
            |> Auth.log_in_user(user, resp)

          {:error, _} ->
            conn
            |> put_status(500)
            |> json(%{"status" => "fatal"})
        end

      {:error, changeset} ->
        conn
        |> put_status(400)
        |> json(changeset_error(changeset))
    end
  end

  def confirm_email(conn, %{"token" => token, "rotation_token" => rotation_token}) do
    user = conn.assigns.current_user

    case Accounts.update_user_email(user, token) do
      {:ok, user} ->

        # Now that the email has been confirmed, also rotate any pending keys
        case KeyStore.commit_rotation(rotation_token, user) do
          {:ok, _} ->
            Enum.each(Tenants.get_data_spaces_by_user(user), fn ds ->
              {:ok, ds_id} = Tenants.to_atom(user, ds.handle)

              Landlord.update_user(Map.from_struct(user), %{"user_id" => user.id, "ds_id" => ds_id})
            end)

            json(conn, %{
              "status" => "ok"
            })

          {:error, _} ->
            json(conn, %{"status" => "fatal"})
        end

      :error ->
        conn
        |> put_status(500)
        |> json(%{"status" => "error"})

    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
  end
end
