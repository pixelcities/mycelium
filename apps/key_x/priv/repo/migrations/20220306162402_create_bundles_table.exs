defmodule KeyX.Repo.Migrations.CreateBundlesTable do
  use Ecto.Migration

  def change do
    create table(:bundles) do
      add :user_id, :uuid, null: false
      add :bundle_id, :integer, null: false
      add :bundle, :text, null: false
      timestamps()
    end

    create index(:bundles, [:user_id])
    create unique_index(:bundles, [:user_id, :bundle_id])
  end
end
