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
