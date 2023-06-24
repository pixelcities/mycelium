defmodule Maestro.Repo.Migrations.AddTaskWorkerHistory do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :worker_history, {:array, :uuid}, default: []
    end
  end
end
