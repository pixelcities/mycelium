defmodule MetaStore.Repo.Migrations.CreateTransformers do
  use Ecto.Migration

  def change do
    create table(:transformers, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :workspace, :string, null: false
      add :type, :text
      add :targets, {:array, :binary_id}
      add :position, {:array, :float}
      add :color, :string
      add :is_ready, :boolean
      add :collections, {:array, :binary_id}
      add :transformers, {:array, :binary_id}
      add :wal, :map

      timestamps()
    end
  end
end
