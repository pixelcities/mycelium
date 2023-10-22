defmodule Landlord.Accounts.UserSetting do
  use Ecto.Schema

  @derive {Jason.Encoder, only: [:key, :value]}
  schema "users_settings" do
    field :key, :string
    field :value, :string
    belongs_to :user, Landlord.Accounts.User, type: :binary_id

    timestamps()
  end
end
