defmodule KeyX.KeyStore.Key do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:key_id, :ciphertext]}
  schema "keys" do
    field :key_id, :binary_id
    field :user_id, :binary_id
    field :ciphertext, :string

    timestamps()
  end

  @doc """
  Ciphertext changeset

  Not much to do as all the heavy lifting is done client side
  """
  def ciphertext_changeset(key, attrs) do
    key
    |> cast(attrs, [:key_id, :ciphertext])
    |> validate_ciphertext()
  end

  def ciphertext_changeset(key, user, attrs) do
    key
    |> cast_user_to_user_id(user)
    |> cast(attrs, [:key_id, :ciphertext])
    |> validate_ciphertext()
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
