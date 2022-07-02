defmodule MetaStore.Projectors.Transformer do
  use Commanded.Projections.Ecto,
    repo: MetaStore.Repo,
    name: "Projectors.Transformer",
    consistency: :strong

  alias Core.Events.{TransformerCreated, TransformerUpdated, TransformerInputAdded}
  alias MetaStore.Projections.Transformer

  project %TransformerCreated{} = transformer, _metadata, fn multi ->
    upsert_transformer(multi, transformer)
  end

  project %TransformerUpdated{} = transformer, _metadata, fn multi ->
    upsert_transformer(multi, transformer)
  end

  project %TransformerInputAdded{} = transformer, _metadata, fn multi ->
    multi
    |> Ecto.Multi.run(:get_transformer, fn repo, _changes ->
      {:ok, repo.get(Transformer, transformer.id)}
    end)
    |> Ecto.Multi.update(:transformer, fn %{get_transformer: s} ->
      Transformer.changeset(s, %{
        collections: Enum.concat(s.collections || [], [transformer.collection])
      })
    end)
  end

  defp upsert_transformer(multi, transformer) do
    multi
    |> Ecto.Multi.run(:get_transformer, fn repo, _changes ->
      {:ok, repo.get(Transformer, transformer.id) || %Transformer{id: transformer.id} }
    end)
    |> Ecto.Multi.insert_or_update(:transformer, fn %{get_transformer: s} ->
      Transformer.changeset(s, %{
        workspace: transformer.workspace,
        type: transformer.type,
        targets: transformer.targets,
        position: transformer.position,
        color: transformer.color,
        is_ready: transformer.is_ready,
        collections: transformer.collections,
        transformers: transformer.transformers,
        wal: transformer.wal
      })
    end)
  end

end
