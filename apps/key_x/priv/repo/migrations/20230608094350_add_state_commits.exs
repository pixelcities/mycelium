defmodule KeyX.Repo.Migrations.AddStateCommits do
  use Ecto.Migration

  def change do
    alter table(:state) do
      add :message_id, :integer, default: 0
      add :message_ids, {:array, :integer}, default: []
      add :in_transit, {:array, :integer}, default: []
    end
  end
end
