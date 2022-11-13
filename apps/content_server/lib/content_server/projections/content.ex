defmodule ContentServer.Projections.Content do
  use Ecto.Schema
  import Ecto.Changeset

  alias ContentServer.Projections.Page

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  schema "content" do
    field :workspace, :string
    field :type, :string
    field :access, {:array, :map}
    field :content, :string
    field :widget_id, :binary_id

    belongs_to :page, Page

    timestamps()
  end

  def changeset(transformer, attrs) do
    transformer
    |> cast(attrs, [:workspace, :type, :page_id, :access, :content, :widget_id])
  end
end

