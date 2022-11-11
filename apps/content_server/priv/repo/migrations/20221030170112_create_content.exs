defmodule ContentServer.Repo.Migrations.CreateContent do
  use Ecto.Migration

  def change do
    create table(:content, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :workspace, :string, null: false
      add :type, :text
      add :access, {:array, :map}
      add :content, :text
      add :widget_id, :uuid

      timestamps()
    end
  end
end
