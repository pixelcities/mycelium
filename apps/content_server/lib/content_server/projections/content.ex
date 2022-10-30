defmodule ContentServer.Projections.Content do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}

  schema "content" do
    field :workspace, :string
    field :type, :string
    field :access, :string, default: "internal"
    field :content, :string
    field :widget_id, :binary_id

    timestamps()
  end

  def changeset(transformer, attrs) do
    transformer
    |> cast(attrs, [:workspace, :type, :access, :content, :widget_id])
  end
end

