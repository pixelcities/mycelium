defmodule Landlord.Repo.Migrations.AddUserSettings do
  use Ecto.Migration

  def change do
    create table(:users_settings) do
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :key, :string, null: false
      add :value, :text
      timestamps()
    end

    create index(:users_settings, [:user_id])
    create unique_index(:users_settings, [:user_id, :key])
  end
end
