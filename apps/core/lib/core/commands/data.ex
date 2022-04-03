defmodule Core.Commands.CreateDataURI do
  use Commanded.Command,
    id: :string,
    workspace: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace])
  end
end

