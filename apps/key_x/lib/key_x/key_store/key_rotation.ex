defmodule KeyX.KeyStore.KeyRotation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "keys_rotations" do
    field :token, :string
    field :ciphertext, :string
    belongs_to :key, KeyX.KeyStore.Key, type: :binary_id
    belongs_to :user, KeyX.KeyStore.Key, type: :binary_id, foreign_key: :user_id, references: :user_id

    timestamps(updated_at: false)
  end

  def rotation_changeset(key, token, user, attrs) do
    key
    |> cast(%{:token => token}, [:token])
    |> cast_user_to_user_id(user)
    |> cast(attrs, [:key_id, :ciphertext])
    |> validate_key_id()
    |> validate_ciphertext()
  end

  defp validate_key_id(changeset) do
    changeset
    |> validate_required([:key_id])
  end

  defp validate_ciphertext(changeset) do
    changeset
    |> validate_required([:ciphertext])
  end

  defp cast_user_to_user_id(key, user) do
    key
    |> cast(%{:user_id => user.id}, [:user_id])
  end

end
