defmodule MetaStore.Repo.Migrations.AddTransformerSignatures do
  use Ecto.Migration

  def change do
    alter table(:transformers) do
      add :signatures, {:array, :string}, default: []
    end
  end
end
