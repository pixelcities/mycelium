defmodule LiaisonServerWeb.KeyStore.ManifestController do
  use LiaisonServerWeb, :controller

  import LiaisonServerWeb.Utils

  alias KeyX.KeyStore

  @doc """
  Get (empty) manifest
  """
  def get(conn, _params) do
    user = conn.assigns.current_user

    manifest = case KeyStore.get_manifest_by_user!(user) do
      nil -> %{}
      manifest -> manifest
    end

    json(conn, manifest)
  end

  @doc """
  Create or update manifest
  """
  def put(conn, params) do
    user = conn.assigns.current_user

    case KeyStore.upsert_manifest(user, params) do
      {:ok, manifest} ->
        json(conn, manifest)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(400)
        |> json(changeset_error(changeset))
    end
  end

end
