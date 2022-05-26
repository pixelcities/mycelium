defmodule Maestro.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :type, :string, null: false
      add :task, :map, null: false
      add :worker, :uuid, null: true
      add :is_completed, :boolean, default: false

      timestamps()
    end
  end
end
