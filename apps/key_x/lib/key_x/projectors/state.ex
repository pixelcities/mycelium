defmodule KeyX.Projectors.State do
  use Commanded.Projections.Ecto,
    repo: KeyX.Repo,
    consistency: :strong

  require Logger

  alias Core.Events.SecretShared
  alias KeyX.Protocol.{State, StateMessages}

  project %SecretShared{receiver: receiver} = secret, _metadata, fn multi ->
    multi
    |> Ecto.Multi.run(:state, fn repo, _ ->
      case repo.one(from s in State,
        where: s.user_id == ^receiver,
        select: [:id]
      ) do
        # To create a valid association, the first share requires the state model to be created
        nil -> repo.insert(%State{State.new(receiver) | state: ""})
        state -> {:ok, state}
      end
    end)
    |> Ecto.Multi.insert(:message, fn %{state: state} ->
      %StateMessages{state_id: state.id, message_id: secret.message_id}
    end)
  end

  @impl true
  def error({:error, error}, _event, _failure_context) do
    Logger.error(fn -> "State projector failed:" <> inspect(error) end)

    :skip
  end
end
