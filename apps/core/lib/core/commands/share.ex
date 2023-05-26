defmodule Core.Commands.ShareSecret do
  use Commanded.Command,
    key_id: :string,
    owner: :string,
    receiver: :string,
    ciphertext: :string

  def validate_key_id(changeset, validation_fun, user_id) do
    changeset
    |> validate_change(:key_id, fn :key_id, key_id ->
      # Special case for "hello" messages. Will never be saved by a client.
      if key_id == user_id do
        []
      else
        case validation_fun.(key_id) do
          {:ok, _} -> []
          {:error, _} -> [key_id: "user does not own this key"]
        end
      end
    end)
  end

  def validate_owner(changeset, user_id) do
    changeset
    |> validate_change(:owner, fn :owner, owner ->
      if owner != user_id, do: [owner: "invalid owner"], else: []
    end)
  end

  def handle_validate(changeset) do
    changeset
    |> validate_required([:key_id, :owner, :receiver, :ciphertext])
  end
end

