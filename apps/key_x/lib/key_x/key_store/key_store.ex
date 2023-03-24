defmodule KeyX.KeyStore do
  @moduledoc """
  The KeyStore context.
  """

  import Ecto.Query, warn: false
  require Logger

  alias KeyX.Repo
  alias KeyX.KeyStore.{Key, KeyRotation, Manifest}
  alias Landlord.Accounts.User

  ## Database getters

  def get_key!(id), do: Repo.get!(Key, id)
  def get_manifest!(id), do: Repo.get!(Manifest, id)

  @doc """
  Get a key by id, but also verify the user

  Always returns {:error, nil} when not found, so that
  keys cannot be enumerated or retrieved for other users.
  """
  def get_key_by_id_and_user(key_id, %User{} = user), do: get_key_by_id_and_user(key_id, user.id)
  def get_key_by_id_and_user(key_id, user_id) when is_binary(key_id) do
    try do
      case Repo.one(from k in Key,
          where: k.key_id == ^key_id and k.user_id == ^user_id
      ) do
        nil -> {:error, nil}
        key -> {:ok, key}
      end

    rescue
      e ->
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        {:error, :invalid_id}
    end
  end

  def get_keys!(user, opts \\ []) do
    limit = Keyword.get(opts, :limit, nil)

    Repo.all(from k in Key,
      where: k.user_id == ^user.id,
      limit: ^limit
    )
  end

  def get_manifest_by_user!(user) do
    Repo.one(from m in Manifest,
      where: m.user_id == ^user.id
    )
  end

  ## Database setters

  def create_key(user, attrs) do
    %Key{key_id: Ecto.UUID.generate()}
    |> Key.ciphertext_changeset(user, attrs)
    |> Repo.insert()
  end

  def update_key(key, attrs) do
    key
    |> Key.ciphertext_changeset(attrs)
    |> Repo.insert_or_update()
  end

  def upsert_key(key_id, user, attrs) do
    case get_key_by_id_and_user(key_id, user) do
      {:ok, key} -> update_key(key, attrs)
      {:error, nil} -> update_key(%Key{key_id: key_id, user_id: user.id}, attrs)
      {:error, err} -> {:error, err}
    end
  end

  def delete_key(key) do
    key
    |> Repo.delete()
  end

  def update_manifest(manifest, attrs) do
    manifest
    |> Manifest.changeset(attrs)
    |> Repo.insert_or_update()
  end

  def upsert_manifest(user, attrs) do
    case get_manifest_by_user!(user) do
      nil -> update_manifest(%Manifest{user_id: user.id}, attrs)
      manifest -> update_manifest(manifest, attrs)
    end
  end

  ## Key rotation

  @doc """
  Prepare to batch update multiple keys

  The new keys are inserted into a seperate rotation table so that
  no existing keys are overwritten until the rotation is complete.

  The token parameter may be any string, but will be required in
  commit_rotation/2 to actually overwrite any keys.

  Key rotation is often triggered due to email/password changes, so
  the new keys may not be final when, for example, a typo was made in
  the form. Only once the change is final, should commit_rotation/2 be
  called.

  Finally, the insert is transactional and will abort when any single
  one of the keys in the payload has an error.
  """
  def prepare_rotation(token, user, keys) do
    changesets = Enum.map(keys, fn key ->
      KeyRotation.rotation_changeset(%KeyRotation{}, token, user, key) end)

    Ecto.Multi.new()
    |> Ecto.Multi.run(:keys,
      fn _, _changes ->
        transactions = Enum.map(changesets, &Repo.insert(&1, []))
        maybe_errors = Enum.filter(transactions, fn {status, _} -> status == :error end)

        case List.first(maybe_errors) do
          nil -> {:ok, {length(transactions), nil}}
          err -> err
        end
      end)
    |> Repo.transaction()
    |> case do
      {:ok, ok} -> {:ok, ok}
      {:error, :keys, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Copy and flush any pending keys from the rotation table

  Most errors should have been caught in prepare_rotation/3, so
  the chances of anything going wrong here are nihil.
  """
  def commit_rotation(token, user) do
    query = from k in KeyRotation,
      where: k.token == ^token and k.user_id == ^user.id
    keys = Repo.all(query)

    Ecto.Multi.new()
    |> Ecto.Multi.run(:rotate,
      fn _, _changes ->
        transactions = Enum.map(keys, fn new ->
          Repo.one(from k in Key,
            where: k.key_id == ^new.key_id and k.user_id == ^new.user_id
          )
          |> Key.ciphertext_changeset(%{ciphertext: new.ciphertext})
          |> Repo.update()
        end)
        maybe_errors = Enum.filter(transactions, fn {status, _} -> status == :error end)

        case List.first(maybe_errors) do
          nil -> {:ok, {length(transactions), nil}}
          err -> err
        end

      end)
    |> Ecto.Multi.delete_all(:delete_all, query)
    |> Repo.transaction()
    |> case do
      {:ok, ok} -> {:ok, ok}
      {:error, :keys, changeset, _} -> {:error, changeset}
    end

  end

end

