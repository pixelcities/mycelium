defmodule Core.Commands.CreateMPC do
  use Commanded.Command,
    id: :string,
    nr_parties: :integer

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :nr_parties])
  end
end

defmodule Core.Commands.ShareMPCPartial do
  use Commanded.Command,
    id: :string,
    owner: :string,
    value: :float

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :value])
  end
end

defmodule Core.Commands.ShareMPCResult do
  use Commanded.Command,
    id: :string,
    value: :float

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :value])
  end
end

