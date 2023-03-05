defmodule Landlord.Repo.Migrations.AddUserRole do
  use Ecto.Migration

  def up do
    alter table(:data_spaces__users) do
      add :role, :string, null: true
    end

    execute "UPDATE data_spaces__users SET role = 'collaborator'"

    alter table(:data_spaces__users) do
      modify :role, :string, null: false
    end
  end

  def down do
    alter table(:data_spaces__users) do
      remove :role
    end
  end
end
