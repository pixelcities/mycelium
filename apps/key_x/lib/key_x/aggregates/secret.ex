defmodule KeyX.Aggregates.Secret do
  @moduledoc """
  Secret share aggregate
  """

  defstruct message_id: 0,
            key_id: nil,
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
  def execute(%Secret{message_id: message_id}, %ShareSecret{} = secret) do
    SecretShared.new(secret,
      message_id: message_id + 1,
      date: NaiveDateTime.utc_now()
    )
  end

  # State mutators

  def apply(%Secret{} = secret, %SecretShared{} = event) do
    %Secret{secret |
      message_id: event.message_id,
      key_id: event.key_id,
      owner: event.owner,
      receiver: event.receiver,
      ciphertext: event.ciphertext,
      date: event.date
    }
  end
end
