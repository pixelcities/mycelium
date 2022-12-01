defmodule ContentServer.Repo.Migrations.AddContentHeight do
  use Ecto.Migration

  def change do
    alter table(:content) do
      add :height, :integer
    end
  end
end
