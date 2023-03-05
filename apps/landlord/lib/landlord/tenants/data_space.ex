defmodule Landlord.Tenants.DataSpace do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @derive {Jason.Encoder, only: [:id, :handle, :name, :key_id]}
  schema "data_spaces" do
    field :handle, :string
    field :name, :string
    field :key_id, :string

    has_many :data_spaces__users, Landlord.Tenants.DataSpaceUser
    has_many :users, through: [:data_spaces__users, :user]

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

defmodule Landlord.Tenants.DataSpaceUser do
  use Ecto.Schema

  schema "data_spaces__users" do
    field :role, :string
    belongs_to :user, Landlord.Accounts.User, type: :binary_id
    belongs_to :data_space, Landlord.Tenants.DataSpace, type: :binary_id
  end
end
