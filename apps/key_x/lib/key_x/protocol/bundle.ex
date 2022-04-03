defmodule KeyX.Protocol.Bundle do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:user_id, :bundle_id, :bundle]}
  schema "bundles" do
    field :user_id, :binary_id
    field :bundle_id, :integer
    field :bundle, :string

    timestamps()
  end

  def changeset(bundle, attrs) do
    bundle
    |> cast(attrs, [:bundle_id, :bundle])
  end

end
