defmodule MetaStore.Projectors.Source do
  use Commanded.Projections.Ecto,
    repo: MetaStore.Repo,
    name: "Projectors.Source",
    consistency: :strong

  alias Core.Events.{SourceCreated, SourceUpdated}
  alias MetaStore.Projections.Source
  alias MetaStore.Projectors

  project %SourceCreated{} = source, _metadata, fn multi ->
    upsert_source(multi, source)
  end

  # TODO: This does not always trigger the multi? (event number?)
  project %SourceUpdated{} = source, _metadata, fn multi ->
    upsert_source(multi, source)
  end

  defp upsert_source(multi, source) do
    multi
    |> Ecto.Multi.run(:get_source, fn repo, _changes ->
      {:ok, repo.get(Source, source.id) || %Source{id: source.id} }
    end)
    |> Ecto.Multi.insert_or_update(:source, fn %{get_source: s} ->
      Source.changeset(s, %{
        workspace: source.workspace,
        uri: source.uri,
        type: source.type,
        is_published: source.is_published
      })
    end)
    |> Ecto.Multi.merge(fn %{source: _} ->
      Ecto.Multi.new()
      |> Projectors.Schema.upsert_schema(source, [is_source: true])
    end)
  end

end
