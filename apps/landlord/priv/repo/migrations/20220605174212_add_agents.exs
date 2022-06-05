defmodule Landlord.Repo.Migrations.AddAgents do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_agent, :boolean, default: false
    end
  end
end
