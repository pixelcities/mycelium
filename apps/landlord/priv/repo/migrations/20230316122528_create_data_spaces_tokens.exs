defmodule Landlord.Repo.Migrations.CreateDataSpacesTokens do
  use Ecto.Migration

  def change do
    create table(:data_spaces_tokens) do
      add :data_space_id, references(:data_spaces, type: :uuid, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:data_spaces_tokens, [:data_space_id, :sent_to])
    create unique_index(:data_spaces_tokens, [:token])
  end
end
