defmodule Core.Commands.SendUserNotification do
  use Commanded.Command,
    id: :binary_id,
    type: :string,
    message: :string,
    receiver: :binary_id,
    is_urgent: {:boolean, default: false}

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :type, :message, :receiver])
    |> validate_inclusion(:type, ["info", "error"])
  end
end

defmodule Core.Commands.MarkNotificationRead do
  use Commanded.Command,
    id: :binary_id,
    read_by: :binary_id

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :read_by])
  end
end

