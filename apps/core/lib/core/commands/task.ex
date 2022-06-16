defmodule Core.Commands.CreateTask do
  use Commanded.Command,
    id: :string,
    type: :string,
    task: :map,
    worker: :string,
    fragments: {{:array, :string}, default: []}

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :type, :task])
  end
end

defmodule Core.Commands.AssignTask do
  use Commanded.Command,
    id: :string,
    type: :string,
    task: :string,
    worker: :string,
    fragments: {{:array, :string}, default: []}

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :worker])
  end
end

defmodule Core.Commands.CompleteTask do
  use Commanded.Command,
    id: :string,
    is_completed: :boolean,
    fragments: {{:array, :string}, default: []}

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :is_completed])
  end
end

