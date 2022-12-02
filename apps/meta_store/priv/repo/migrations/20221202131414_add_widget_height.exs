defmodule MetaStore.Repo.Migrations.AddWidgetHeight do
  use Ecto.Migration

  def change do
    alter table(:widgets) do
      add :height, :integer
    end
  end
end
