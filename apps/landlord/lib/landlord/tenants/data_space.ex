defmodule Landlord.Tenants.DataSpace do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Landlord.Tenants.{
    DataSpace,
    DataSpaceUser,
    Subscription
  }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @derive {Jason.Encoder, only: [:id, :handle, :name, :key_id, :manifest]}
  schema "data_spaces" do
    field :handle, :string
    field :name, :string
    field :key_id, :string
    field :description, :string
    field :picture, :string
    field :manifest, :map
    field :is_active, :boolean, default: false

    has_many :data_spaces__users, DataSpaceUser
    has_many :users, through: [:data_spaces__users, :user]
    has_one :subscription, Subscription

    timestamps()
  end

  def changeset(data_space, attrs, opts \\ []) do
    is_active = Keyword.get(opts, :is_active, false)

    data_space
    |> cast(Map.put(attrs, :is_active, is_active), [:handle, :name, :key_id, :description, :picture, :manifest, :is_active])
    |> validate_required([:key_id])
    |> validate_handle()
  end

  def set_is_active_changeset(data_space) do
    change(data_space, is_active: true)
  end

  def set_manifest_changeset(data_space, manifest) do
    change(data_space, manifest: manifest)
  end

  def set_key_id_changeset(data_space, key_id) do
    change(data_space, key_id: key_id)
  end

  @doc """
  Get a list of all active data spaces

  This includes having an active subscription and having the data space
  itself be actived as well (there is an active commanded application for
  this data space).
  """
  def get_active_data_spaces(opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    {subscription, subscription_is_active} = Subscription.active_subscription_clause()

    from d in DataSpace,
      left_join: assoc(d, :subscription), as: ^subscription,
      where: ^(dynamic([d], d.handle == "trial" or (d.is_active == true and ^subscription_is_active))),
      preload: ^preload
  end

  def get_inactive_data_spaces(opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    {subscription, subscription_is_active} = Subscription.active_subscription_clause()

    from d in DataSpace,
      left_join: assoc(d, :subscription), as: ^subscription,
      where: ^(dynamic([d], d.handle != "trial" and (d.is_active != true or not ^subscription_is_active))),
      preload: ^preload
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
