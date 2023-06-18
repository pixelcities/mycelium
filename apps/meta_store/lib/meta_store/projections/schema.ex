defmodule MetaStore.Projections.Schema do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder, only: [:id, :key_id, :tag, :column_order, :columns, :shares]}

  schema "schemas" do
    field :key_id, :binary_id
    field :column_order, {:array, :string}
    field :tag, :string
    belongs_to :source, MetaStore.Projections.Source,
      where: [collection: nil]
    belongs_to :collection, MetaStore.Projections.Collection,
      where: [source: nil]
    has_many :columns, MetaStore.Projections.Column
    many_to_many :shares, MetaStore.Projections.Share, join_through: "schemas__shares", on_replace: :delete

    timestamps()
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:key_id, :column_order, :tag, :source_id, :collection_id])
  end

end

defmodule MetaStore.Projections.Column do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder, only: [:id, :key_id, :concept_id, :lineage, :shares]}

  schema "columns" do
    field :concept_id, :binary_id
    field :key_id, :binary_id
    field :lineage, :binary_id
    belongs_to :schema, MetaStore.Projections.Schema
    many_to_many :shares, MetaStore.Projections.Share, join_through: "columns__shares", on_replace: :delete

    timestamps()
  end

  def changeset(column, attrs) do
    column
    |> cast(attrs, [:concept_id, :key_id, :lineage, :schema_id])
  end

end

defmodule MetaStore.Projections.Share do
  use Ecto.Schema

  @primary_key {:id, :string, read_after_writes: true}
  @foreign_key_type :string
  @derive {Jason.Encoder, only: [:principal, :type]}

  schema "shares" do
    field :principal, :string
    field :type, :string
  end
end

