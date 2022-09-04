defmodule KeyX.Aggregates.Secret do
  @moduledoc """
  Secret share aggregate

  TODO: Add and track committed secret shares
  """

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
