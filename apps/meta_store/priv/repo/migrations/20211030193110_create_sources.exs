defmodule MetaStore.Repo.Migrations.CreateSources do
  use Ecto.Migration

  def change do
    # sources
    create table(:sources, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :workspace, :string, null: false
      add :uri, :string
      add :type, :text
      add :is_published, :boolean

      timestamps()
    end

    # shares
    execute """
      CREATE TABLE shares (
        id text GENERATED ALWAYS AS ('share:' || principal || ':' || type) STORED PRIMARY KEY,
        principal text,
        type text
      );
    """

    # schemas
    create table(:schemas, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :key_id, :uuid
      add :column_order, {:array, :string}

      timestamps()
      add :source_id, references(:sources, type: :uuid, on_delete: :delete_all), null: false
    end

    create table(:schemas__shares) do
      add :schema_id, references(:schemas, type: :uuid)
      add :share_id, references(:shares, type: :text)
    end

    # columns
    create table(:columns, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :key_id, :uuid
      add :schema_id, references(:schemas, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create table(:columns__shares) do
      add :column_id, references(:columns, type: :uuid)
      add :share_id, references(:shares, type: :text)
    end
  end
end
