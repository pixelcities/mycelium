defmodule LiaisonServerWeb.DataSpaces.DataSpaceController do
  use LiaisonServerWeb, :controller

  require Logger
  import LiaisonServerWeb.Utils

  alias Landlord.Tenants
  alias Landlord.Tenants.SubscriptionApi

  @doc """
  Get all data spaces for this user
  """
  def list_data_spaces(conn, _params) do
    user = conn.assigns.current_user

    data_spaces = Tenants.get_data_spaces_by_user(user)
    inactive =
      Tenants.get_inactive_data_spaces_by_user(user)
      |> Enum.filter(fn ds -> Tenants.is_owner?(ds, user) end)

    json(conn, %{
      "active" => data_spaces,
      "inactive" => inactive
    })
  end

  @doc """
  Get data space by handle
  """
  def get_data_space(conn, %{"handle" => handle}) do
    user = conn.assigns.current_user

    case Tenants.get_data_space_by_user_and_handle(user, handle) do
      {:ok, data_space} ->
        json(conn, data_space)

      {:error, _err} -> send_json_resp(conn, 404)
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
          {:error, :invalid_membership} -> send_json_resp(conn, 403)
          _ -> send_json_resp(conn, 500)
        end

      {:error, _err} -> send_json_resp(conn, 404)
    end
  end

  @doc """
  Accept the invitation as a new data space member
  """
  def accept_invite(conn, %{"token" => token}) do
    user = conn.assigns.current_user

    case Tenants.accept_invite(user, token) do
      {:ok, _} -> json(conn, %{"status" => "ok"})
      {:error, :invalid_token} -> send_json_resp(conn, 403)
      _ -> send_json_resp(conn, 500)
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
          {:error, :invalid_membership} -> send_json_resp(conn, 403)
          _ -> send_json_resp(conn, 500)
        end

      {:error, _err} -> send_json_resp(conn, 404)
    end
  end

  def cancel_invite(conn, %{"handle" => handle, "email" => email}) do
    user = conn.assigns.current_user

    case Tenants.get_data_space_by_user_and_handle(user, handle) do
      {:ok, data_space} ->
        case Tenants.cancel_invite(data_space, user, email) do
          {:ok, _} -> json(conn, %{"status" => "ok"})
          {:error, :invalid_membership} -> send_json_resp(conn, 403)
          _ -> send_json_resp(conn, 500)
        end

      {:error, _err} -> send_json_resp(conn, 404)
    end
  end

  def leave_data_space(conn, %{"handle" => handle}) do
    user = conn.assigns.current_user

    case Tenants.get_data_space_by_user_and_handle(user, handle) do
      {:ok, data_space} ->
        case Tenants.delete_user_from_data_space(data_space, user) do
          {:ok, _} -> json(conn, %{"status" => "ok"})
          _ -> send_json_resp(conn, 500)
        end

      {:error, _err} -> send_json_resp(conn, 404)
    end
  end

  def prepare_data_space(conn, %{
    "name" => name,
    "handle" => handle,
    "key_id" => key_id,
    "plan" => plan,
    "interval" => _interval
  })
  do
    user = conn.assigns.current_user

    case SubscriptionApi.get_plan_id(plan) do
      nil -> send_json_resp(conn, 400)
      product_id ->
        case Tenants.prepare_data_space(user, %{name: name, handle: handle, key_id: key_id}) do
          {:ok, data_space} ->
            case SubscriptionApi.generate_redirect(product_id, user.email, data_space.handle) do
              {:ok, uri} -> json(conn, %{"uri" => uri})
              _ -> send_json_resp(conn, 500)
            end
          e ->
            Logger.error(Exception.format(:error, e))
            send_json_resp(conn, 400)
        end
    end
  end

  def activate_data_space(conn, %{"checkout_id" => checkout_id}) do
    user = conn.assigns.current_user

    case Tenants.get_data_space_by_checkout_id(user, checkout_id) do
      {:ok, data_space} ->
        unless data_space.is_active do
          Tenants.create_data_space(user, data_space, [user_create: true])
        end

        json(conn, "")

      {:error, _} -> send_json_resp(conn, 404)
    end
  end

  defp send_json_resp(conn, 400), do: conn |> put_status(400) |> json(%{"status" => "bad request"})
  defp send_json_resp(conn, 403), do: conn |> put_status(403) |> json(%{"status" => "forbidden"})
  defp send_json_resp(conn, 404), do: conn |> put_status(404) |> json(%{"status" => "not found"})
  defp send_json_resp(conn, 500), do: conn |> put_status(500) |> json(%{"status" => "error"})
end
