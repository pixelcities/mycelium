defmodule Landlord.Repo.Migrations.CreateDataSpaces do
  use Ecto.Migration

  def change do
    create table(:data_spaces, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :handle, :string, null: false
      add :name, :string
      add :key_id, :string

      timestamps()
    end

    create unique_index(:data_spaces, [:handle])

    create table(:data_spaces__users) do
      add :data_space_id, references(:data_spaces, type: :uuid)
      add :user_id, references(:users, type: :uuid)
    end

  end
end
