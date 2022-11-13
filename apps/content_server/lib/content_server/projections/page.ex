defmodule ContentServer.Projections.Page do
  use Ecto.Schema
  import Ecto.Changeset

  alias ContentServer.Projections.Content

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  schema "pages" do
    field :workspace, :string
    field :access, {:array, :map}
    field :key_id, :binary_id

    has_many :content, Content

    timestamps()
  end

  def changeset(transformer, attrs) do
    transformer
    |> cast(attrs, [:workspace, :access, :key_id])
  end
end

