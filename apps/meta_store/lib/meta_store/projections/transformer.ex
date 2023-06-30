defmodule MetaStore.Projections.Transformer do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}

  schema "transformers" do
    field :workspace, :string
    field :type, :string
    field :targets, {:array, :binary_id}, default: []
    field :position, {:array, :float}, default: [0.0, 0.0]
    field :color, :string, default: "#000000"
    field :is_ready, :boolean, default: false
    field :collections, {:array, :binary_id}, default: []
    field :transformers, {:array, :binary_id}, default: []
    field :wal, :map
    field :error, :string
    field :signatures, {:array, :string}, default: []

    timestamps()
  end

  def changeset(transformer, attrs) do
    transformer
    |> cast(attrs, [:workspace, :type, :targets, :position, :color, :is_ready, :collections, :transformers, :wal, :error, :signatures])
  end
end

