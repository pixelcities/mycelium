defmodule KeyX.Protocol do
  @moduledoc """
  The Protocol context.
  """

  import Ecto.Query, warn: false
  require Logger

  alias KeyX.Repo
  alias KeyX.Protocol.{Bundle, State}

  ## Database getters

  def get_bundle!(id), do: Repo.get!(Bundle, id)

  def get_bundle_by_user_id!(user_id) do
    Repo.one(from b in Bundle,
      where: b.user_id == ^user_id,
      limit: 1
    )
  end

  def get_max_bundle_id_by_user!(user) do
    Repo.one(from b in Bundle,
      select: max(b.bundle_id),
      where: b.user_id == ^user.id
    )
  end

  def get_nr_bundles_by_user_id!(user_id) do
    Repo.one(from b in Bundle,
      select: count(b.bundle_id),
      where: b.user_id == ^user_id
    )
  end

  def get_state!(id), do: Repo.get!(State, id)

  def get_state_by_user!(user) do
    Repo.one(from s in State,
      where: s.user_id == ^user.id
    )
  end

  ## Database setters

  def create_bundle(user, attrs) do
    %Bundle{user_id: user.id}
    |> Bundle.changeset(attrs)
    |> Repo.insert()
  end

  def pop_bundle(user_id, bundle_id) do
    bundle = Repo.one(from b in Bundle,
      where: b.user_id == ^user_id and b.bundle_id == ^bundle_id
    )
    bundle_data = bundle.bundle

    # Bundle are one time use only
    Repo.delete(bundle)

    bundle_data
  end

  def update_state(state, attrs) do
    state
    |> State.changeset(attrs)
    |> Repo.insert_or_update()
  end

  def upsert_state(user, attrs) do
    case get_state_by_user!(user) do
      nil -> update_state(%State{user_id: user.id}, attrs)
      state -> update_state(state, attrs)
    end
  end

end

