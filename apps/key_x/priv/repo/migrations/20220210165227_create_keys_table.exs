defmodule KeyX.Repo.Migrations.CreateKeysTable do
  use Ecto.Migration

  def change do
    create table(:keys) do
      add :key_id, :uuid, null: false
      add :user_id, :uuid, null: false
      add :ciphertext, :text, null: false
      timestamps()
    end

    create index(:keys, [:user_id])
    create unique_index(:keys, [:key_id, :user_id])

    create table(:keys_rotations) do
      add :token, :string, null: false
      add :key_id,
        references(:keys,
          type: :uuid,
          column: :key_id,
          with: [user_id: :user_id],
          on_delete: :delete_all
        ), null: false
      add :user_id, :uuid, null: false
      add :ciphertext, :text, null: false
      timestamps(updated_at: false)
    end

    create index(:keys_rotations, [:token])
    create unique_index(:keys_rotations, [:token, :key_id, :user_id])
  end
end
