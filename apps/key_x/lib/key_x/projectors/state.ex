defmodule KeyX.Projectors.State do
  use Commanded.Projections.Ecto,
    repo: KeyX.Repo,
    consistency: :strong

  require Logger

  alias Core.Events.SecretShared
  alias KeyX.Protocol.State

  project %SecretShared{receiver: receiver} = secret, _metadata, fn multi ->
    multi
    |> Ecto.Multi.run(:state, fn repo, _ ->
      case repo.one(from s in State,
        where: s.user_id == ^receiver,
        select: [:id, :in_transit],
        lock: "FOR UPDATE"
      ) do
        nil -> {:ok, %State{State.new(receiver) | state: ""}}
        state -> {:ok, state}
      end
    end)
    |> Ecto.Multi.insert_or_update(:upsert, fn %{state: state} ->
      State.message_sent(state, secret.message_id)
    end)
  end

  @impl true
  def error({:error, error}, _event, _failure_context) do
    Logger.error(fn -> "State projector failed:" <> inspect(error) end)

    :skip
  end
end
