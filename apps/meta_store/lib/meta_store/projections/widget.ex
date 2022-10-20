defmodule MetaStore.Projections.Widget do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}

  schema "widgets" do
    field :workspace, :string
    field :type, :string
    field :position, {:array, :float}, default: [0.0, 0.0]
    field :color, :string, default: "#000000"
    field :is_ready, :boolean, default: false
    field :settings, :map, default: %{}
    field :collection, :binary_id

    timestamps()
  end

  def changeset(transformer, attrs) do
    transformer
    |> cast(attrs, [:workspace, :type, :position, :color, :is_ready, :settings, :collection])
  end
end

