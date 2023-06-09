defmodule KeyX.Protocol.StateMessages do
  use Ecto.Schema

  schema "state_messages" do
    field :message_id, :binary_id

    belongs_to :state, KeyX.Protocol.State

    timestamps(updated_at: false)
  end
end
