defmodule MetaStore.Repo.Migrations.AddTransformerError do
  use Ecto.Migration

  def change do
    alter table(:transformers) do
      add :error, :string
    end
  end
end
