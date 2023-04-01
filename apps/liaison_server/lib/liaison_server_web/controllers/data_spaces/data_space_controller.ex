defmodule LiaisonServerWeb.DataSpaces.DataSpaceController do
  use LiaisonServerWeb, :controller

  import LiaisonServerWeb.Utils
  alias Landlord.Tenants

  @doc """
  Get all data spaces for this user
  """
  def list_data_spaces(conn, _params) do
    user = conn.assigns.current_user

    json(conn, Tenants.get_data_spaces_by_user(user))
  end

  @doc """
  Get data space by handle
  """
  def get_data_space(conn, %{"handle" => handle}) do
    user = conn.assigns.current_user

    case Tenants.get_data_space_by_user_and_handle(user, handle) do
      {:ok, data_space} ->
        json(conn, data_space)

      {:error, _err} ->
        conn
        |> put_status(404)
        |> json(%{
          "status" => "not found"
        })
    end
  end

  @doc """
  Invite a user by email to a data space

  This requires the current user to be the data space owner.
  """
  def invite_to_data_space(conn, %{"handle" => handle, "recipient" => recipient}) do
    user = conn.assigns.current_user

    case Tenants.get_data_space_by_user_and_handle(user, handle) do
      {:ok, data_space} ->
        case Tenants.invite_to_data_space(data_space, user, recipient, &Routes.data_space_url(get_external_host(), :accept_invite, &1)) do
          {:ok, _} -> json(conn, %{"status" => "ok"})
          {:error, :invalid_membership} ->
            conn
            |> put_status(403)
            |> json(%{"status" => "forbidden"})
          _ ->
            conn
            |> put_status(500)
            |> json(%{"status" => "error"})
        end

      {:error, _err} ->
        conn
        |> put_status(404)
        |> json(%{
          "status" => "not found"
        })
    end
  end

  @doc """
  Accept the invitation as a new data space member
  """
  def accept_invite(conn, %{"token" => token}) do
    user = conn.assigns.current_user

    case Tenants.accept_invite(user, token) do
      {:ok, _} -> json(conn, %{"status" => "ok"})
      {:error, :invalid_token} ->
        conn
        |> put_status(403)
        |> json(%{"status" => "forbidden"})
      _ ->
        conn
        |> put_status(500)
        |> json(%{"status" => "error"})
    end
  end

  @doc """
  Confirm a new member after they accepted the invite

  This signals that the metadata key was shared at last, and the new member
  is fully ready to start collaborating.
  """
  def confirm_member(conn, %{"handle" => handle, "member" => new_member_id}) do
    user = conn.assigns.current_user

    case Tenants.get_data_space_by_user_and_handle(user, handle) do
      {:ok, data_space} ->
        case Tenants.confirm_member(data_space, user, new_member_id) do
          {:ok, _} -> json(conn, %{"status" => "ok"})
          {:error, :invalid_membership} ->
            conn
            |> put_status(403)
            |> json(%{"status" => "forbidden"})
          _ ->
            conn
            |> put_status(500)
            |> json(%{"status" => "error"})
        end

      {:error, _err} ->
        conn
        |> put_status(404)
        |> json(%{
          "status" => "not found"
        })
    end
  end

  def cancel_invite(conn, %{"handle" => handle, "email" => email}) do
    user = conn.assigns.current_user

    case Tenants.get_data_space_by_user_and_handle(user, handle) do
      {:ok, data_space} ->
        case Tenants.cancel_invite(data_space, user, email) do
          {:ok, _} -> json(conn, %{"status" => "ok"})
          {:error, :invalid_membership} ->
            conn
            |> put_status(403)
            |> json(%{"status" => "forbidden"})
          _ ->
            conn
            |> put_status(500)
            |> json(%{"status" => "error"})
        end

      {:error, _err} ->
        conn
        |> put_status(404)
        |> json(%{
          "status" => "not found"
        })
    end
  end

  def leave_data_space(conn, %{"handle" => handle}) do
    user = conn.assigns.current_user

    case Tenants.get_data_space_by_user_and_handle(user, handle) do
      {:ok, data_space} ->
        case Tenants.delete_user_from_data_space(data_space, user) do
          {:ok, _} -> json(conn, %{"status" => "ok"})
          _ ->
            conn
            |> put_status(500)
            |> json(%{"status" => "error"})
        end

      {:error, _err} ->
        conn
        |> put_status(404)
        |> json(%{
          "status" => "not found"
        })
    end
  end

end
