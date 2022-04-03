defmodule KeyX.Protocol.State do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:user_id, :state]}
  schema "state" do
    field :user_id, :binary_id
    field :state, :string

    timestamps()
  end

  def changeset(state, attrs) do
    state
    |> cast(attrs, [:state])
  end

end
