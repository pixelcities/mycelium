defmodule MetaStore.Repo.Migrations.AddSchemaIntegrityTag do
  use Ecto.Migration

  def change do
    alter table(:schemas) do
      add :tag, :string
    end
  end
end
