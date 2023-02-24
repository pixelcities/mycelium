defmodule Core.Commands.CreateTask do
  use Commanded.Command,
    id: :string,
    causation_id: :string,
    type: :string,
    task: :map,
    worker: :string,
    fragments: {{:array, :string}, default: []},
    metadata: {:map, default: %{}},
    ttl: {:integer, default: 300}

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :type, :task])
  end
end

defmodule Core.Commands.AssignTask do
  use Commanded.Command,
    id: :string,
    type: :string,
    task: :map,
    worker: :string,
    fragments: {{:array, :string}, default: []},
    metadata: {:map, default: %{}},
    ttl: {:integer, default: 300}

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :worker])
  end
end

defmodule Core.Commands.UnAssignTask do
  use Commanded.Command,
    id: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id])
  end
end

defmodule Core.Commands.CancelTask do
  use Commanded.Command,
    id: :string,
    is_cancelled: :boolean

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :is_cancelled])
  end
end

defmodule Core.Commands.CompleteTask do
  use Commanded.Command,
    id: :string,
    worker: :string,
    is_completed: :boolean,
    fragments: {{:array, :string}, default: []},
    metadata: {:map, default: %{}}

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :is_completed])
  end
end

defmodule Core.Commands.FailTask do
  use Commanded.Command,
    id: :string,
    error: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :error])
  end
end

