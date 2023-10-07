defmodule Landlord.Repo.Migrations.AddDataSpaceManifest do
  use Ecto.Migration

  def change do
    alter table(:data_spaces) do
      add :manifest, :jsonb, null: true
    end
  end
end
