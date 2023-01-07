defmodule LiaisonServerWeb.KeyStore.KeyController do
  use LiaisonServerWeb, :controller

  import LiaisonServerWeb.Utils

  alias KeyX.KeyStore


  @doc """
  Get keys
  """
  def get_keys(conn, %{"limit" => limit})
    when is_integer(limit)
  do
    user = conn.assigns.current_user

    json(conn, KeyStore.get_keys!(user, [limit: limit]))
  end

  def get_keys(conn, _params) do
    user = conn.assigns.current_user

    json(conn, KeyStore.get_keys!(user))
  end

  @doc """
  Create new key
  """
  def create_key(conn, params) do
    user = conn.assigns.current_user

    case KeyStore.create_key(user, params) do
      {:ok, key} ->
        json(conn, key)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(400)
        |> json(changeset_error(changeset))
    end
  end

  @doc """
  Get key by id
  """
  def get_key(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case KeyStore.get_key_by_id_and_user(id, user) do
      {:ok, key} ->
        json(conn, key)

      {:error, _err} ->
        conn
        |> put_status(404)
        |> json(%{
          "status" => "not found"
        })
    end
  end

  @doc """
  Update key
  """
  def put_key(conn, %{"id" => id} = params) do
    user = conn.assigns.current_user

    case KeyStore.upsert_key(id, user, params) do
      {:ok, key} ->
        json(conn, key)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(400)
        |> json(changeset_error(changeset))

      {:error, _err} ->
        conn
        |> put_status(400)
        |> json(%{
          "status" => "Bad request"
        })
    end
  end


  @doc """
  Delete key
  """
  def delete_key(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case KeyStore.get_key_by_id_and_user(id, user) do
      {:ok, key} ->
        case KeyStore.delete_key(key) do
          {:ok, _} ->
            json(conn, %{
              "status" => "ok"
            })

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> put_status(500)
            |> json(changeset_error(changeset))
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
  Batch rotate all keys in payload
  """
  def rotate_keys(conn, %{"token" => token, "keys" => keys}) do
    user = conn.assigns.current_user

    case KeyStore.prepare_rotation(token, user, keys) do
      {:ok, _} ->
        json(conn, %{
          "status" => "ok"
        })

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(400)
        |> json(changeset_error(changeset))
    end
  end

end
