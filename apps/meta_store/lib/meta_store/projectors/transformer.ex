defmodule MetaStore.Projectors.Transformer do
  use Commanded.Projections.Ecto,
    repo: MetaStore.Repo,
    name: "Projectors.Transformer",
    consistency: :strong

  @impl Commanded.Projections.Ecto
  def schema_prefix(_event, %{"ds_id" => ds_id} = _metadata), do: ds_id

  require Logger

  alias Core.Events.{
    TransformerCreated,
    TransformerUpdated,
    TransformerWALUpdated,
    TransformerInputAdded,
    TransformerTargetAdded,
    TransformerTargetRemoved,
    TransformerPositionSet,
    TransformerIsReadySet,
    TransformerErrorSet,
    TransformerApproved,
    TransformerDeleted
  }
  alias MetaStore.Projections.Transformer

  project %TransformerCreated{} = transformer, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    upsert_transformer(multi, transformer, ds_id)
  end

  project %TransformerUpdated{} = transformer, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    upsert_transformer(multi, transformer, ds_id)
  end

  project %TransformerWALUpdated{} = transformer, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Ecto.Multi.run(:get_transformer, fn repo, _changes ->
      {:ok, repo.get(Transformer, transformer.id, prefix: ds_id)}
    end)
    |> Ecto.Multi.update(:transformer, fn %{get_transformer: s} ->
      Transformer.changeset(s, %{
        wal: transformer.wal
      })
    end, prefix: ds_id)
  end

  project %TransformerTargetAdded{} = transformer, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Ecto.Multi.run(:get_transformer, fn repo, _changes ->
      {:ok, repo.get(Transformer, transformer.id, prefix: ds_id)}
    end)
    |> Ecto.Multi.update(:transformer, fn %{get_transformer: s} ->
      Transformer.changeset(s, %{
        targets: Enum.concat(s.targets || [], [transformer.target])
      })
    end, prefix: ds_id)
  end

  project %TransformerTargetRemoved{} = transformer, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Ecto.Multi.run(:get_transformer, fn repo, _changes ->
      {:ok, repo.get(Transformer, transformer.id, prefix: ds_id)}
    end)
    |> Ecto.Multi.update(:transformer, fn %{get_transformer: s} ->
      Transformer.changeset(s, %{
        targets: Enum.reject(s.targets, fn target -> target == transformer.target end)
      })
    end, prefix: ds_id)
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

  project %TransformerPositionSet{} = transformer, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Ecto.Multi.run(:get_transformer, fn repo, _changes ->
      {:ok, repo.get(Transformer, transformer.id, prefix: ds_id)}
    end)
    |> Ecto.Multi.update(:transformer, fn %{get_transformer: s} ->
      Transformer.changeset(s, %{
        position: transformer.position
      })
    end, prefix: ds_id)
  end

  project %TransformerIsReadySet{} = transformer, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Ecto.Multi.run(:get_transformer, fn repo, _changes ->
      case repo.get(Transformer, transformer.id, prefix: ds_id) do
        nil -> {:error, :already_deleted}
        t -> {:ok, t}
      end
    end)
    |> Ecto.Multi.update(:transformer, fn %{get_transformer: s} ->
      Transformer.changeset(s, %{
        is_ready: transformer.is_ready
      })
    end, prefix: ds_id)
  end

  project %TransformerErrorSet{} = transformer, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Ecto.Multi.run(:get_transformer, fn repo, _changes ->
      case repo.get(Transformer, transformer.id, prefix: ds_id) do
        nil -> {:error, :already_deleted}
        t -> {:ok, t}
      end
    end)
    |> Ecto.Multi.update(:transformer, fn %{get_transformer: s} ->
      Transformer.changeset(s, %{
        error: (if transformer.is_error, do: Map.get(transformer, :error, ""), else: nil)
      })
    end, prefix: ds_id)
  end

  project %TransformerApproved{} = transformer, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Ecto.Multi.run(:get_transformer, fn repo, _changes ->
      {:ok, repo.get(Transformer, transformer.id, prefix: ds_id)}
    end)

    |> Ecto.Multi.update(:transformer, fn %{get_transformer: s} ->
      Transformer.changeset(s, %{
        signatures: transformer.signatures
      })
    end, prefix: ds_id)
  end

  project %TransformerDeleted{} = transformer, %{"ds_id" => ds_id} = _metadata, fn multi ->
    multi
    |> Ecto.Multi.run(:get_transformer, fn repo, _changes ->
      {:ok, repo.get(Transformer, transformer.id, prefix: ds_id)}
    end)
    |> Ecto.Multi.delete(:delete, fn %{get_transformer: s} -> s end)
  end


  # Error handlers

  @impl true
  def error({:error, :already_deleted}, _event, _failure_context) do
    :skip
  end

  @impl true
  def error({:error, error}, _event, _failure_context) do
    Logger.error(fn -> "Transformer projector is skipping event due to:" <> inspect(error) end)

    :skip
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
