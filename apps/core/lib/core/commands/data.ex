defmodule Core.Commands.CreateDataURI do
  use Commanded.Command,
    id: :string,
    workspace: :string,
    ds: :string,
    type: :string

  def validate_type(changeset, strict_types) when is_list(strict_types) do
    changeset
    |> validate_inclusion(:type, strict_types)
  end

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace])
    |> validate_inclusion(:type, ["source", "collection"])
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

