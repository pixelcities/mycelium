defmodule KeyX.Repo.Migrations.CreateStateTable do
  use Ecto.Migration

  def change do
    create table(:state) do
      add :user_id, :uuid, null: false
      add :state, :text, null: false
      timestamps()
    end

    create index(:state, [:user_id])
  end
end
