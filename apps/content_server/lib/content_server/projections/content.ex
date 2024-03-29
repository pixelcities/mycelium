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
    field :draft, :string
    field :widget_id, :binary_id
    field :height, :integer

    belongs_to :page, Page

    timestamps()
  end

  def changeset(transformer, attrs) do
    transformer
    |> cast(attrs, [:workspace, :type, :page_id, :access, :content, :draft, :widget_id, :height])
  end
end

