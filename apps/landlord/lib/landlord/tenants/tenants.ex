defmodule Landlord.Tenants do
  @moduledoc """
  The Tenants context.

  Each tenant is a group of users behind a subscription. Users may be part
  of multiple tenants.

  A tenant provides the data space for users to collaborate in.
  """

  import Ecto.Query, warn: false
  require Logger

  alias Landlord.Repo
  alias Landlord.Accounts.{User, UserNotifier}
  alias Landlord.Tenants.{DataSpace, DataSpaceUser, DataSpaceToken}

  ## Database getters

  @doc """
  Get data space handles

  Note that a handle is expected to be an atom.
  """
  def get() do
    try do
      tenants = Repo.all(from d in DataSpace, select: d.handle)
        |> Enum.map(fn handle -> String.to_atom(handle) end)
      {:ok, tenants}
    rescue
      e in Postgrex.Error ->
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        {:error, e.postgres.code}
      e ->
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        reraise e, __STACKTRACE__
    end
  end

  def get!() do
    {:ok, tenants} = __MODULE__.get()
    tenants
  end

  @doc """
  Gets all data spaces
  """
  def get_data_spaces(), do: Repo.all(DataSpace)

  @doc """
  Get data spaces for given user
  """
  def get_data_spaces_by_user(user) do
    Repo.all(from d in DataSpace,
      join: u in assoc(d, :users),
      where: u.id == ^user.id
    )
  end

  @doc """
  Get data space role for given user
  """
  def get_data_space_role(user, data_space) do
    case Repo.one(from d in DataSpaceUser,
      where: d.data_space_id == ^data_space.id and d.user_id == ^user.id
    ) do
      nil -> {:error, nil}
      data_space_user -> {:ok, data_space_user.role}
    end
  end

  @doc """
  Get a single data space
  """
  def get_data_space!(id), do: Repo.get!(DataSpace, id)
  def get_data_space_by_handle(handle) when is_atom(handle), do:
    get_data_space_by_handle(Atom.to_string(handle))
  def get_data_space_by_handle(handle) do
    Repo.one(from d in DataSpace,
      where: d.handle == ^handle
    )
  end

  @doc """
  Get a single data space by user and handle

  Users should not be able to get data spaces they are not a part of.
  """
  def get_data_space_by_user_and_handle(user, handle) do
    case Repo.one(from d in DataSpace,
      join: u in assoc(d, :users),
      where: d.handle == ^handle and u.id == ^user.id
    ) do
      nil -> {:error, nil}
      data_space -> {:ok, data_space}
    end
  end

  @doc """
  Convert handle to atom

  Verifies the user has access to the handle and that it already exists
  """
  def to_atom(user, handle) do
    case get_data_space_by_user_and_handle(user, handle) do
      {:ok, data_space} -> {:ok, String.to_existing_atom(data_space.handle)}
      {:error, _} -> {:error, :invalid_handle}
    end
  end

  @doc """
  Confirm a user is member of the given data space
  """
  def is_member?(%DataSpace{} = data_space, %User{} = user), do: is_member?(data_space, user.id)
  def is_member?(%DataSpace{} = data_space, user_id) do
    query = from u in User,
      join: d in assoc(u, :data_spaces),
      where: d.id == ^data_space.id and u.id == ^user_id

    Repo.exists?(query)
  end

  def is_owner?(%DataSpace{} = data_space, %User{} = user), do: is_owner?(data_space, user.id)
  def is_owner?(%DataSpace{} = data_space, user_id) do
    query = from u in DataSpaceUser,
      where: u.user_id == ^user_id and u.data_space_id == ^data_space.id and u.role == "owner"

    Repo.exists?(query)
  end


  ## Database setters

  @doc """
  Create a new data space

  A dataspace requires a metadata key, which should be created
  beforehand. The key id is then associated with the data space.

  Collaborators may be invited using invite_to_data_space/4.
  """
  def create_data_space(%User{} = user, %{key_id: _key_id} = attrs, opts \\ []) do
    user_create = Keyword.get(opts, :user_create, false)

    {:ok, data_space} = %DataSpace{}
    |> DataSpace.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:data_spaces__users, [%{user: user, role: "owner", status: "confirmed"}])
    |> Repo.insert()

    # Verified by the DataSpace changeset
    handle = String.to_atom(data_space.handle)

    Landlord.Registry.dispatch(handle)

    if user_create do
      Landlord.create_user(Map.put(Map.from_struct(user), :role, "owner"), %{"user_id" => user.id, "ds_id" => handle})
    end
  end

  @doc """
  Invite a user to a data space

  ## Examples

      iex> invite_to_data_space(data_space, user, "hello@pixelcities.io", &Routes.data_space_path(host, :accept_invite, &1))
      {:ok, _}

  """
  def invite_to_data_space(%DataSpace{} = data_space, %User{} = user, recipient_email, email_url_fun, _attrs \\ %{}) do
    if not is_owner?(data_space, user) || email_is_member?(data_space, recipient_email) do
      {:error, :invalid_membership}
    else
      {encoded_token, invite_token} = DataSpaceToken.build_invite_token(data_space, recipient_email)

      with {:ok, _} <- Repo.insert(invite_token),
           {:ok, _} <- UserNotifier.deliver_invitation(recipient_email, user.email, email_url_fun.(encoded_token)),
           {:ok, handle} <- to_atom(user, data_space.handle)
      do
        Landlord.invite_user(%{email: recipient_email, role: "collaborator"}, %{"user_id" => user.id, "ds_id" => handle})
      else
        err -> err
      end
    end
  end

  def accept_invite(user, token) do
    with {:ok, query} <- DataSpaceToken.verify_invite_token_query(user, token),
         %DataSpace{} = data_space <- Repo.one(query),
         {:ok, %{}} <- Repo.transaction(accept_invite_multi(user, data_space))
    do
      # Verified by the DataSpace changeset
      handle = String.to_existing_atom(data_space.handle)

      Landlord.accept_invite(%{email: user.email, id: user.id}, %{"user_id" => user.id, "ds_id" => handle})
    else
      _ -> {:error, :invalid_token}
    end
  end

  def confirm_member(%DataSpace{} = data_space, %User{} = user, new_member_id) do
    if email_is_member?(data_space, user.email) do
      case Repo.one(from u in DataSpaceUser, where: u.user_id == ^new_member_id and u.data_space_id == ^data_space.id) do
        nil -> {:error, :member_has_not_accepted_invite}
        changeset ->
          data_space_user = Repo.update!(DataSpaceUser.confirm_member_changeset(changeset)) |> Repo.preload(:user)
          handle = String.to_existing_atom(data_space.handle)

          Landlord.confirm_invite(%{email: data_space_user.user.email}, %{"user_id" => user.id, "ds_id" => handle})
          Landlord.create_user(Map.put(Map.from_struct(data_space_user.user), :role, data_space_user.role), %{"user_id" => user.id, "ds_id" => handle})
      end
    else
      {:error, :invalid_membership}
    end
  end

  def cancel_invite(%DataSpace{} = data_space, %User{} = user, invite_email) do
    if email_is_member?(data_space, user.email) do
      case Repo.one(from t in DataSpaceToken, where: t.sent_to == ^invite_email and t.data_space_id == ^data_space.id) do
        nil -> {:error, :no_such_invite}
        changeset ->
          Repo.delete!(changeset)
          handle = String.to_existing_atom(data_space.handle)

          Landlord.cancel_invite(%{email: invite_email}, %{"user_id" => user.id, "ds_id" => handle})
      end
    else
      {:error, :invalid_membership}
    end
  end

  @doc """
  Directly add a user to a data space.

  Only to be used internally. The metadata key still has te be shared beforehand.
  """
  def add_user_to_data_space(%DataSpace{} = data_space, %User{} = user) do
    Repo.transaction(accept_invite_multi(user, data_space))
  end

  defp accept_invite_multi(user, data_space) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:user, %DataSpaceUser{user: user, data_space: data_space, role: "collaborator", status: "pending"})
    |> Ecto.Multi.delete_all(:tokens, DataSpaceToken.user_and_data_space_query(user, data_space))
  end

  defp email_is_member?(%DataSpace{} = data_space, email) do
    query = from u in User,
      join: d in assoc(u, :data_spaces),
      where: d.id == ^data_space.id and u.email == ^email

    Repo.exists?(query)
  end
end

