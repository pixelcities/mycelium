defmodule Core.Types.Schemas.Schema do
  use Ecto.Schema

  import Ecto.Changeset
  alias Core.Types.Schemas.{Share, Column}

  @primary_key false
  @derive {Jason.Encoder, only: [:id, :key_id, :tag, :column_order, :columns, :shares]}

  schema "schema" do
    field :id, :string
    field :key_id, :string
    field :column_order, {:array, :string}
    embeds_many :columns, Column
    embeds_many :shares, Share
    field :tag, :string
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:id, :key_id, :column_order, :tag])
    |> cast_embed(:columns)
    |> cast_embed(:shares)
  end

  def new(attrs) do
    changeset(%__MODULE__{}, attrs)
    |> validate_required([:id])
  end

  def dump(%__MODULE__{} = schema) do
    %{
      id: schema.id,
      key_id: schema.key_id,
      column_order: schema.column_order,
      columns: Enum.map(schema.columns, fn column ->
        Column.dump(column)
      end),
      shares: Enum.map(schema.shares, fn share ->
        Share.dump(share)
      end),
      tag: schema.tag
    }
  end
end

