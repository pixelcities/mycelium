defmodule ContentServer.Repo.Migrations.CreatePageProjection do
  use Ecto.Migration

  def change do
    create table(:pages, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :workspace, :string, null: false
      add :access, {:array, :map}
      add :key_id, :string, null: true

      timestamps()
    end

    alter table(:content) do
      add :page_id, references(:pages, type: :uuid, on_delete: :delete_all), null: false
    end

  end
end
