defmodule MetaStore.Repo.Migrations.AddColumnLineage do
  use Ecto.Migration

  def change do
    alter table(:columns) do
      add :lineage, :uuid, null: true
    end
  end
end
