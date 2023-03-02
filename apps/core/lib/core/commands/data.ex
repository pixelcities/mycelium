defmodule Core.Commands.CreateDataURI do
  use Commanded.Command,
    id: :string,
    workspace: :string,
    ds: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace])
  end
end

defmodule Core.Commands.RequestTruncateDataset do
  use Commanded.Command,
    id: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id])
  end
end

defmodule Core.Commands.TruncateDataset do
  use Commanded.Command,
    id: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id])
  end
end

defmodule Core.Commands.RequestDeleteDataset do
  use Commanded.Command,
    id: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id])
  end
end

defmodule Core.Commands.DeleteDataset do
  use Commanded.Command,
    id: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id])
  end
end

