defmodule Core.Commands.CreateUser do
  use Commanded.Command,
    id: :string,
    email: :string,
    role: :string,
    name: :string,
    picture: :string,
    last_active_at: :naive_datetime

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :email, :role])
    |> validate_inclusion(:role, ["owner", "collaborator"])
  end
end

defmodule Core.Commands.UpdateUser do
  use Commanded.Command,
    id: :string,
    email: :string,
    role: :string,
    name: :string,
    picture: :string,
    last_active_at: :naive_datetime

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id])
    |> validate_inclusion(:role, ["owner", "collaborator"])
  end
end

defmodule Core.Commands.SetUserActivity do
  use Commanded.Command,
    id: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id])
  end
end

defmodule Core.Commands.DeleteUser do
  use Commanded.Command,
    id: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id])
  end
end

defmodule Core.Commands.InviteUser do
  use Commanded.Command,
    email: :string,
    role: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:email, :role])
    |> validate_inclusion(:role, ["owner", "collaborator"])
  end
end

defmodule Core.Commands.AcceptInvite do
  use Commanded.Command,
    email: :string,
    id: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:email, :id])
  end
end

defmodule Core.Commands.ConfirmInvite do
  use Commanded.Command,
    email: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:email])
  end
end

defmodule Core.Commands.CancelInvite do
  use Commanded.Command,
    email: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:email])
  end
end

