defmodule Landlord.Repo.Migrations.AddUserTokenExtraInfo do
  use Ecto.Migration

  def change do
    alter table(:users_tokens) do
      add :extra, :map
    end
  end
end
