defmodule ContentServer.Repo.Migrations.AddPageOrder do
  use Ecto.Migration

  def change do
    alter table(:pages) do
      add :content_order, {:array, :binary_id}
    end
  end
end
