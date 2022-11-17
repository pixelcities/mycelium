defmodule MetaStore.Repo.Migrations.AddWidgetContent do
  use Ecto.Migration

  def change do
    alter table(:widgets) do
      add :access, {:array, :map}
      add :content, :string
      add :is_published, :boolean
    end
  end
end
