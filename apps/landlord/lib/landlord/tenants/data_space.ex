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
    field :description, :string
    field :picture, :string
    field :is_active, :boolean, default: false

    has_many :data_spaces__users, Landlord.Tenants.DataSpaceUser
    has_many :users, through: [:data_spaces__users, :user]

    timestamps()
  end

  def changeset(data_space, attrs, opts \\ []) do
    is_active = Keyword.get(opts, :is_active, false)

    data_space
    |> cast(Map.put(attrs, :is_active, is_active), [:handle, :name, :key_id, :description, :picture, :is_active])
    |> validate_required([:key_id])
    |> validate_handle()
  end

  def set_is_active_changeset(data_space) do
    change(data_space, is_active: true)
  end


  defp validate_handle(changeset) do
    changeset
    |> validate_required([:handle])
    |> validate_format(:handle, ~r/^\w+$/, message: "must be a single word")
    |> validate_length(:handle, min: 3, max: 63)
    |> unsafe_validate_unique(:handle, Landlord.Repo)
    |> unique_constraint(:handle)
  end
end

defmodule Landlord.Tenants.DataSpaceUser do
  use Ecto.Schema
  import Ecto.Changeset

  schema "data_spaces__users" do
    field :role, :string
    field :status, :string
    belongs_to :user, Landlord.Accounts.User, type: :binary_id
    belongs_to :data_space, Landlord.Tenants.DataSpace, type: :binary_id
  end

  def confirm_member_changeset(data_space_user) do
    change(data_space_user, status: "confirmed")
  end

end
