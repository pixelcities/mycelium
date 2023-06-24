defmodule Maestro.Projections.Task do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "tasks" do
    field :causation_id, :binary_id
    field :type, :string
    field :task, :map
    field :worker, :binary_id
    field :worker_history, {:array, :binary_id}, default: []
    field :fragments, {:array, :string}, default: []
    field :metadata, :map, default: %{}
    field :is_cancelled, :boolean, default: false
    field :is_completed, :boolean, default: false

    timestamps()
  end

  def changeset(task, attrs) do
    task
    |> cast(attrs, [:causation_id, :type, :task, :worker, :worker_history, :fragments, :metadata])
  end
end

