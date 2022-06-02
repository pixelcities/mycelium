defmodule MetaStore.Projections.Collection do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  schema "collections" do
    field :workspace, :string
    field :type, :string
    field :uri, :string
    field :targets, {:array, :binary_id}, default: []
    field :position, {:array, :float}, default: [0.0, 0.0]
    field :color, :string, default: "#000000"
    field :is_ready, :boolean, default: false
    has_one :schema, MetaStore.Projections.Schema

    timestamps()
  end

  def changeset(collection, attrs) do
    collection
    |> cast(attrs, [:workspace, :type, :uri, :targets, :position, :color, :is_ready])
  end
end

