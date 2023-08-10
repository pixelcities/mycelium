defmodule MetaStore.Projectors.Source do
  use Commanded.Projections.Ecto,
    repo: MetaStore.Repo,
    name: "Projectors.Source",
    consistency: :strong

  @impl Commanded.Projections.Ecto
  def schema_prefix(_event, %{"ds_id" => ds_id} = _metadata), do: ds_id

  require Logger

  alias Core.Events.{
    SourceCreated,
    SourceUpdated,
    SourceURIUpdated,
    SourceDeleted
  }
  alias MetaStore.Projections.Source
  alias MetaStore.Projectors

  project %SourceCreated{} = source, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    upsert_source(multi, source, ds_id)
  end

  # TODO: This does not always trigger the multi? (event number?)
  project %SourceUpdated{} = source, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    upsert_source(multi, source, ds_id)
  end

  project %SourceURIUpdated{uri: uri} = source, %{"ds_id" => ds_id} = _metadata, fn multi ->
    multi
    |> Ecto.Multi.run(:get_source, fn repo, _changes ->
      {:ok, repo.get(Source, source.id, prefix: ds_id)}
    end)
    |> Ecto.Multi.update(:update, fn %{get_source: s} ->
      Source.changeset(s, %{
        uri: hd(uri)
      })
    end)
  end

  project %SourceDeleted{} = source, %{"ds_id" => ds_id} = _metadata, fn multi ->
    multi
    |> Ecto.Multi.run(:get_source, fn repo, _changes ->
      {:ok, repo.get(Source, source.id, prefix: ds_id)}
    end)
    |> Ecto.Multi.delete(:delete, fn %{get_source: s} -> s end)
  end

  @impl true
  def error({:error, error}, _event, _failure_context) do
    Logger.error(fn -> "Source projector is skipping event due to:" <> inspect(error) end)

    :skip
  end

  defp upsert_source(multi, source, ds_id) do
    multi
    |> Ecto.Multi.run(:get_source, fn repo, _changes ->
      {:ok, repo.get(Source, source.id, prefix: ds_id) || %Source{id: source.id} }
    end)
    |> Ecto.Multi.insert_or_update(:source, fn %{get_source: s} ->
      Source.changeset(s, %{
        workspace: source.workspace,
        uri: hd(source.uri),
        type: source.type,
        is_published: source.is_published
      })
    end, prefix: ds_id)
    |> Ecto.Multi.merge(fn %{source: _} ->
      Ecto.Multi.new()
      |> Projectors.Schema.upsert_schema(source, [is_source: true, tenant: ds_id])
    end)
  end

end
