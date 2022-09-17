defmodule MetaStore.Projectors.Transformer do
  use Commanded.Projections.Ecto,
    repo: MetaStore.Repo,
    name: "Projectors.Transformer",
    consistency: :strong

  alias Core.Events.{TransformerCreated, TransformerUpdated, TransformerInputAdded}
  alias MetaStore.Projections.Transformer

  project %TransformerCreated{} = transformer, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    upsert_transformer(multi, transformer, ds_id)
  end

  project %TransformerUpdated{} = transformer, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    upsert_transformer(multi, transformer, ds_id)
  end

  project %TransformerInputAdded{} = transformer, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Ecto.Multi.run(:get_transformer, fn repo, _changes ->
      {:ok, repo.get(Transformer, transformer.id, prefix: ds_id)}
    end)
    |> Ecto.Multi.update(:transformer, fn %{get_transformer: s} ->
      Transformer.changeset(s, %{
        collections: Enum.concat(s.collections || [], [transformer.collection])
      })
    end, prefix: ds_id)
  end

  defp upsert_transformer(multi, transformer, ds_id) do
    multi
    |> Ecto.Multi.run(:get_transformer, fn repo, _changes ->
      {:ok, repo.get(Transformer, transformer.id, prefix: ds_id) || %Transformer{id: transformer.id} }
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
    end, prefix: ds_id)
  end

end
