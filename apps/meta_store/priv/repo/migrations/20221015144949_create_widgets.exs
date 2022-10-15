defmodule MetaStore.Repo.Migrations.CreateWidgets do
  use Ecto.Migration

  def change do
    create table(:widgets, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :workspace, :string, null: false
      add :type, :text
      add :position, {:array, :float}
      add :color, :string
      add :is_ready, :boolean
      add :collection, :uuid

      timestamps()
    end
  end
end
