defmodule MetaStore.Repo.Migrations.AddWidgetSettings do
  use Ecto.Migration

  def change do
    alter table(:widgets) do
      add :settings, :map
    end
  end
end
