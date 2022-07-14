defmodule LiaisonServerWeb.DataSpaces.DataSpaceController do
  use LiaisonServerWeb, :controller

  alias Landlord.Tenants

  @doc """
  Get all data spaces for this user
  """
  def list(conn, _params) do
    user = conn.assigns.current_user

    json(conn, Tenants.get_data_spaces_by_user(user))
  end

  @doc """
  Get data space by handle
  """
  def get(conn, %{"handle" => handle}) do
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

end
