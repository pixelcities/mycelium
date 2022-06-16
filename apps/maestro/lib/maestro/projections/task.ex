defmodule Maestro.Projections.Task do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "tasks" do
    field :type, :string
    field :task, :map
    field :worker, :binary_id
    field :fragments, {:array, :string}, default: []
    field :is_completed, :boolean, default: false

    timestamps()
  end

  def changeset(task, attrs) do
    task
    |> cast(attrs, [:type, :task, :worker, :fragments])
  end
end

