defmodule KeyX.Protocol do
  @moduledoc """
  The Protocol context.
  """

  import Ecto.Query, warn: false
  require Logger

  alias KeyX.Repo
  alias KeyX.Protocol.{Bundle, State, StateMessages}

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

  def get_old_messages_by_user(user, duration_in_minutes \\ 15) do
    Repo.all(from s in State,
      join: m in assoc(s, :messages),
      where: s.user_id == ^user.id and m.inserted_at < ago(^duration_in_minutes, "minute"),
      select: m.message_id
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

  @doc """
  Update the state blob

  A state blob should come with a list of message ids that are now
  known to be "committed" to the state.

  In transit messages are added to the database by a strongly consistent projector,
  which we will now remove again because they have been received.

  The purpose of tracking the message ids is to be able to identify and optionally
  re-send (old) messages that have not been received.
  """
  def upsert_state(user, %{"state" => _, "message_ids" => message_ids} = attrs) do
    result =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:state, fn repo, _ ->
        case repo.one(from s in State,
          where: s.user_id == ^user.id,
          select: [:id, :user_id]
        ) do
          nil -> {:ok, State.new(user.id)}
          state -> {:ok, state}
        end
      end)
      |> Ecto.Multi.insert_or_update(:upsert, fn %{state: state} -> State.update_state(state, attrs) end)
      |> Ecto.Multi.delete_all(:delete_all, fn %{upsert: state} ->
        from(c in StateMessages, where: c.state_id == ^state.id and c.message_id in ^message_ids)
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{upsert: state}} -> {:ok, state}
      {:error, _, %Ecto.Changeset{} = changeset, _} -> {:error, changeset}
      {:error, failed_operation, failed_value, _} ->
        Logger.error("Failed to upsert state during operation #{inspect(failed_operation)}: #{inspect(failed_value)}")
        {:error, nil}
    end
  end
  def upsert_state(_, _), do: {:error, :invalid_argument}
end

