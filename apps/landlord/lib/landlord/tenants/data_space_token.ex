defmodule Landlord.Tenants.DataSpaceToken do
  use Ecto.Schema
  import Ecto.Query

  @hash_algorithm :sha256
  @rand_size 32

  @invite_validity_in_days 30

  schema "data_spaces_tokens" do
    field :token, :binary
    field :sent_to, :string
    belongs_to :data_space, Landlord.Tenants.DataSpace, type: :binary_id

    timestamps(updated_at: false)
  end

  def build_invite_token(data_space, email) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {
      Base.url_encode64(token, padding: false),
      %Landlord.Tenants.DataSpaceToken{
        token: hashed_token,
        sent_to: email,
        data_space_id: data_space.id
      }
    }
  end

  @doc """
  Verify that an invite token is valid

  The given user must be the one using the token to join the data space, which
  means that a token can only be validated after an account was created with the
  exact same email as the original invite.
  """
  def verify_invite_token_query(%Landlord.Accounts.User{} = user, token) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from token in token_query(hashed_token),
            join: ds in assoc(token, :data_space),
            where: token.inserted_at > ago(@invite_validity_in_days, "day") and token.sent_to == ^user.email,
            select: ds

        {:ok, query}

      :error ->
        :error
    end
  end

  def token_query(token) do
    from Landlord.Tenants.DataSpaceToken, where: [token: ^token]
  end

  def user_and_data_space_query(user, data_space) do
    from t in Landlord.Tenants.DataSpaceToken, where: t.sent_to == ^user.email and t.data_space_id == ^data_space.id
  end

end
