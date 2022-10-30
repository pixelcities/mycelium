defmodule ContentServer.Release do
  @app :content_server

  require Logger

  def migrate do
    for tenant <- tenants() do
      for repo <- repos() do
        {:ok, _} = ensure_repo_created(repo, tenant)
        {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true, prefix: tenant))
      end
    end
  end

  def rollback(repo, version) do
    for tenant <- tenants() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version, prefix: tenant))
    end
  end

  defp tenants() do
    {:ok, _} = Application.ensure_all_started(:landlord)
    case Landlord.Tenants.get() do
      {:ok, tenants} -> tenants
      {:error, :undefined_table} ->
        Logger.error("could not retrieve tenants: Has Landlord been initialized?")
        []
      {:error, e} -> raise e
    end
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp ensure_repo_created(repo, schema) do
    {:ok, _} = Application.ensure_all_started(:ecto_sql)
    {:ok, _} = Application.ensure_all_started(:postgrex)

    opts = repo.config
      |> Keyword.put(:backoff_type, :stop)
      |> Keyword.put(:max_restarts, 0)

    sql = 'CREATE SCHEMA IF NOT EXISTS "#{schema}";'

    task = Task.Supervisor.async_nolink(Ecto.Adapters.SQL.StorageSupervisor, fn ->
      {:ok, conn} = Postgrex.start_link(opts)

      value = Postgrex.query(conn, sql, [], opts)
      GenServer.stop(conn)
      value
    end)

    case Task.yield(task, 5_000) || Task.shutdown(task) do
      {:ok, {:ok, result}} ->
        {:ok, result}
      {:ok, {:error, error}} ->
        {:error, error}
      e ->
        {:error, e}
    end
  end
end
