defmodule MetaStore.Repo.Migrations.CreateCollections do
  use Ecto.Migration

  def change do
    create table(:collections, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :workspace, :string, null: false
      add :type, :text
      add :uri, :string
      add :targets, {:array, :binary_id}
      add :position, {:array, :float}
      add :color, :string
      add :is_ready, :boolean

      timestamps()
    end

    alter table(:schemas) do
      modify :source_id, :uuid, null: true, from: :uuid
      add :collection_id, references(:collections, type: :uuid, on_delete: :delete_all), null: true
    end

  end
end
