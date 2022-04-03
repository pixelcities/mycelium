defmodule KeyX.KeyStore.Manifest do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:user_id, :manifest]}
  schema "manifests" do
    field :user_id, :binary_id
    field :manifest, :map

    timestamps()
  end

  def changeset(manifest, attrs) do
    manifest
    |> cast(attrs, [:manifest])
  end

end
