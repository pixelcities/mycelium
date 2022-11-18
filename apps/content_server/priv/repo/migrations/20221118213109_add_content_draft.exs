defmodule ContentServer.Repo.Migrations.AddContentDraft do
  use Ecto.Migration

  def change do
    alter table(:content) do
      add :draft, :text
    end
  end
end
