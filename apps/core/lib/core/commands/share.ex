defmodule Core.Commands.ShareSecret do
  use Commanded.Command,
    key_id: :string,
    owner: :string,
    receiver: :string,
    ciphertext: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:key_id, :owner, :receiver, :ciphertext])
  end
end

