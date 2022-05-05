defmodule LiaisonServerWeb.Protocol.ProtocolController do
  use LiaisonServerWeb, :controller
  import LiaisonServerWeb.Utils

  alias KeyX.Protocol

  @doc """
  Create a new bundle
  """
  def create_bundle(conn, %{"bundle_id" => _bundle_id, "bundle" => _bundle} = params) do
    user = conn.assigns.current_user

    {:ok, bundle} = Protocol.create_bundle(user, params)

    json(conn, bundle)
  end

  @doc """
  Get the latest bundle id
  """
  def get_latest_bundle(conn, _params) do
    user = conn.assigns.current_user

    bundle_id = case Protocol.get_max_bundle_id_by_user!(user) do
      nil -> nil
      bundle_id -> bundle_id
    end

    json(conn, bundle_id)
  end

  @doc """
  Get an available bundle id for given user
  """
  def get_bundle(conn, %{"user_id" => remote_user_id} = _params) do
    _user = conn.assigns.current_user

    bundle_id = case Protocol.get_bundle_by_user_id!(remote_user_id) do
      nil -> nil
      bundle -> bundle.bundle_id
    end

    # Just an int, but that's valid json
    json(conn, bundle_id)
  end

  @doc """
  Get the actual bundle, and then delete it
  """
  def delete_bundle(conn, %{"user_id" => remote_user_id, "bundle_id" => bundle_id} = _params) do
    _user = conn.assigns.current_user

    bundle = Protocol.pop_bundle(remote_user_id, bundle_id)

    json(conn, bundle)
  end

  @doc """
  Get state
  """
  def get_state(conn, _params) do
    user = conn.assigns.current_user

    state = Protocol.get_state_by_user!(user)

    json(conn, state)
  end

  @doc """
  Create or update state
  """
  def put_state(conn, %{"state" => _} = params) do
    user = conn.assigns.current_user

    case Protocol.upsert_state(user, params) do
      {:ok, state} ->
        json(conn, state)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(400)
        |> json(changeset_error(changeset))
    end
  end


end
