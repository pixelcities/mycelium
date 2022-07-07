defmodule Maestro.Repo.Migrations.AddTaskMetadata do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :metadata, :map, default: %{}
    end
  end
end
