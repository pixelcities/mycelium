defmodule Core.Commands.CreateMetadata do
  use Commanded.Command,
    id: :string,
    workspace: :string,
    metadata: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :metadata])
  end
end

defmodule Core.Commands.UpdateMetadata do
  use Commanded.Command,
    id: :string,
    workspace: :string,
    metadata: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :metadata])
  end
end

