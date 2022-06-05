defmodule Landlord.Tenants do
  @moduledoc """
  The Tenants context.

  Each tenant is a group of users behind a subscription. Users may be part
  of multiple tenants.

  A tenant provides the data space for users to collaborate in.
  """

  import Ecto.Query, warn: false

  alias Landlord.Repo
  alias Landlord.Accounts.User
  alias Landlord.Tenants.DataSpace

  ## Database getters

  @doc """
  Get data space handles

  Note that a handle is expected to be an atom.
  """
  def get() do
    Repo.all(from d in DataSpace, select: d.handle)
    |> Enum.map(fn handle -> String.to_atom(handle) end)
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
  Get a single data space
  """
  def get_data_space!(id), do: Repo.get!(DataSpace, id)


  ## Database setters

  @doc """
  Create a new data space

  A dataspace requires a metadata key, which should be created
  beforehand. The key id is then associated with the data space.

  Collaborators may be invited using invite_to_data_space/4.
  """
  def create_data_space(%User{} = user, %{key_id: _key_id} = attrs) do
    data_space = %DataSpace{}
    |> DataSpace.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:users, [user])
    |> Repo.insert()

    Landlord.Registry.dispatch(String.to_atom(data_space.handle))
  end

  @doc """
  Invite a user to a data space

  It is expected that the metadata key has been shared as well.
  """
  def invite_to_data_space(%DataSpace{} = data_space, %User{} = user, %User{} = invitee, _attrs \\ %{}) do
    if not is_member?(data_space, user) || is_member?(data_space, invitee) do
      {:error, :invalid_membership}
    else
      users = Repo.all(from u in User, join: d in assoc(u, :data_spaces))

      data_space
      |> Repo.preload(:users)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:users, users ++ [invitee])
      |> Repo.update!
    end
  end

  defp is_member?(%DataSpace{} = data_space, %User{} = user) do
    query = from u in User,
      join: d in assoc(u, :data_spaces),
      where: d.id == ^data_space.id and u.id == ^user.id

    Repo.exists?(query)
  end
end

