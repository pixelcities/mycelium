defmodule Core.Types.Share do
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field :type, :string
    field :principal, :string
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:type, :principal])
    |> validate_required([:type])
  end

  def new(attrs) do
    changeset(%__MODULE__{}, attrs)
  end
end

defmodule Core.Types.Column do
  use Ecto.Schema

  import Ecto.Changeset
  alias Core.Types.Share

  @primary_key false
  embedded_schema do
    field :id, :string
    field :concept_id, :string
    field :key_id, :string
    embeds_many :shares, Share
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:id, :concept_id, :key_id])
    |> cast_embed(:shares, with: &Share.changeset/2)
    |> validate_required([:id, :concept_id, :key_id])
  end
end


defmodule Core.Types.Schema do
  use Ecto.Schema

  import Ecto.Changeset
  alias Core.Types.{Share, Column}

  @primary_key false
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
    |> cast(attrs, [:id, :key_id, :tag])
    |> cast_embed(:columns)
    |> cast_embed(:shares)
  end

  def new(attrs) do
    changeset(%__MODULE__{}, attrs)
    |> validate_required([:id])
  end
end

