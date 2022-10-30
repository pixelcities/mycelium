defmodule Core.Commands.CreateContent do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    type: :string,
    access: {:string, default: "internal"},
    widget_id: :binary_id,
    content: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :type, :access])
    |> validate_inclusion(:type, ["static", "widget"])
    |> validate_inclusion(:access, ["public", "internal"])
    |> validate_one_of([:widget_id, :content])
  end
end

defmodule Core.Commands.UpdateContent do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    type: :string,
    access: {:string, default: "internal"},
    widget_id: :binary_id,
    content: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :type, :access])
    |> validate_inclusion(:type, ["static", "widget"])
    |> validate_inclusion(:access, ["public", "internal"])
    |> validate_one_of([:widget_id, :content])
  end
end

defmodule Core.Commands.DeleteContent do
  use Commanded.Command,
    id: :binary_id,
    workspace: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace])
  end
end
