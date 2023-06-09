defmodule KeyX.Protocol.State do
  use Ecto.Schema
  import Ecto.Changeset

  alias KeyX.Protocol.State

  @derive {Jason.Encoder, only: [:user_id, :state]}
  schema "state" do
    field :user_id, :binary_id
    field :state, :string

    has_many :messages, KeyX.Protocol.StateMessages

    timestamps()
  end

  def new(user_id) do
    %State{
      user_id: user_id
    }
  end

  def update_state(changeset, %{"state" => _state} = attrs) do
    changeset
    |> cast(attrs, [:state])
  end
end
