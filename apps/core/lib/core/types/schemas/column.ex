defmodule Core.Types.Schemas.Column do
  use Ecto.Schema

  import Ecto.Changeset
  alias Core.Types.Schemas.Share

  @primary_key false
  @derive {Jason.Encoder, only: [:id, :key_id, :concept_id, :shares]}

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

  def dump(%__MODULE__{} = column) do
    %{Map.from_struct(column) |
      shares: Enum.map(column.shares, fn share ->
        Share.dump(share)
      end)
    }
  end
end

