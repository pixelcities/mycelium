defmodule MetaStore.Repo.Migrations.AddConceptId do
  use Ecto.Migration

  def change do
    alter table(:columns) do
      add :concept_id, :uuid, null: false
    end
  end
end
