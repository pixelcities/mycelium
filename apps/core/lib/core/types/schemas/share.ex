defmodule Core.Types.Schemas.Share do
  use Ecto.Schema

  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:principal, :type]}

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

  def dump(%__MODULE__{} = share) do
    %{
      type: share.type,
      principal: share.principal
    }
  end
end

