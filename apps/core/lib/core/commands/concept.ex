defmodule Core.Commands.CreateConcept do
  use Commanded.Command,
    id: :string,
    workspace: :string,
    concept: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :concept])
  end
end

defmodule Core.Commands.UpdateConcept do
  use Commanded.Command,
    id: :string,
    workspace: :string,
    concept: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :concept])
  end
end

