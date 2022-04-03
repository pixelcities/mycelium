defmodule Core.Commands.CreateUser do
  use Commanded.Command,
    id: :string,
    email: :string,
    name: :string,
    picture: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :email])
  end
end

defmodule Core.Commands.UpdateUser do
  use Commanded.Command,
    id: :string,
    email: :string,
    name: :string,
    picture: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id])
  end
end

