defmodule MetaStore.Projections.Source do
  use Ecto.Schema
  import Ecto.Changeset

  alias MetaStore.Projections.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "sources" do
    field :workspace, :string
    field :type, :string
    field :uri, :string
    field :is_published, :boolean

    has_one :schema, Schema

    timestamps()
  end

  def changeset(source, attrs) do
    source
    |> cast(attrs, [:workspace, :type, :uri, :is_published])
  end
end

