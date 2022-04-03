defmodule SecretLifespan do
  @moduledoc """
  Just nuke the secret aggregate as we only act as the messenger and
  no further command validation is required for this secret
  """

  @behaviour Commanded.Aggregates.AggregateLifespan

  def after_event(_event), do: :stop
  def after_command(_command), do: :stop
  def after_error(_error), do: :stop
end

defmodule KeyX.Aggregates.Secret do
  defstruct key_id: nil,
            owner: nil,
            receiver: nil,
            ciphertext: nil,
            date: nil

  alias KeyX.Aggregates.Secret
  alias Core.Commands.ShareSecret
  alias Core.Events.SecretShared

  @doc """
  Forward a secret
  """
  def execute(%Secret{}, %ShareSecret{} = secret) do
    SecretShared.new(secret, date: NaiveDateTime.utc_now())
  end

  # State mutators

  def apply(%Secret{} = secret, %SecretShared{} = event) do
    %Secret{secret |
      key_id: event.key_id,
      owner: event.owner,
      receiver: event.receiver,
      ciphertext: event.ciphertext,
      date: event.date
    }
  end
end
