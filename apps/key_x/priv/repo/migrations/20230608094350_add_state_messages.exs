defmodule KeyX.Repo.Migrations.AddStateMessages do
  use Ecto.Migration

  def change do
    create table(:state_messages) do
      add :state_id, references(:state, on_delete: :delete_all), null: false
      add :message_id, :uuid, null: false

      timestamps(updated_at: false)
    end

    create unique_index(:state_messages, [:state_id, :message_id])
  end
end
