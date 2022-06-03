defmodule Landlord.Tenants.DataSpace do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @derive {Jason.Encoder, only: [:id, :email, :name, :picture]}
  schema "data_spaces" do
    field :handle, :string
    field :name, :string
    field :key_id, :string
    many_to_many :users, Landlord.Accounts.User, join_through: "data_spaces__users"

    timestamps()
  end

  def changeset(data_space, attrs) do
    data_space
    |> cast(attrs, [:handle, :name, :key_id])
    |> validate_handle()
  end

  defp validate_handle(changeset) do
    changeset
    |> validate_required([:handle])
    |> validate_format(:handle, ~r/^\w+$/, message: "must be a single word")
    |> unsafe_validate_unique(:handle, Landlord.Repo)
    |> unique_constraint(:handle)
  end
end
