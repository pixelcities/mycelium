defmodule Core.Commands.CreatePage do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    access: {{:array, :map}, default: [%{type: "internal"}]},
    key_id: :binary_id

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :access])
    |> validate_shares(:access)
  end
end

defmodule Core.Commands.UpdatePage do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    access: {{:array, :map}, default: [%{type: "internal"}]},
    key_id: :binary_id

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :access])
    |> validate_shares(:access)
  end
end

defmodule Core.Commands.DeletePage do
  use Commanded.Command,
    id: :binary_id,
    workspace: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace])
  end
end

defmodule Core.Commands.CreateContent do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    type: :string,
    page_id: :binary_id,
    access: {{:array, :map}, default: [%{type: "internal"}]},
    widget_id: :binary_id,
    content: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :type, :page_id, :access])
    |> validate_inclusion(:type, ["static", "widget"])
    |> validate_shares(:access)
    |> validate_one_of([:widget_id, :content])
  end
end

defmodule Core.Commands.UpdateContent do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    type: :string,
    page_id: :binary_id,
    access: {{:array, :map}, default: [%{type: "internal"}]},
    widget_id: :binary_id,
    content: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :type, :page_id, :access])
    |> validate_inclusion(:type, ["static", "widget"])
    |> validate_shares(:access)
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

