defmodule KeyX.Repo.Migrations.CreateManifestTable do
  use Ecto.Migration

  def change do
    create table(:manifests) do
      add :user_id, :uuid, null: false
      add :manifest, :map, default: %{}
      timestamps()
    end

    create unique_index(:manifests, :user_id)
  end
end
