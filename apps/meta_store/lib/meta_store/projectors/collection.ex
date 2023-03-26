defmodule MetaStore.Projectors.Collection do
  use Commanded.Projections.Ecto,
    repo: MetaStore.Repo,
    name: "Projectors.Collection",
    consistency: :strong

  @impl Commanded.Projections.Ecto
  def schema_prefix(_event, %{"ds_id" => ds_id} = _metadata), do: ds_id

  alias Core.Events.{
    CollectionCreated,
    CollectionUpdated,
    CollectionColorSet,
    CollectionSchemaUpdated,
    CollectionTargetAdded,
    CollectionTargetRemoved,
    CollectionIsReadySet,
    CollectionDeleted
  }
  alias MetaStore.Projections.Collection
  alias MetaStore.Projectors

  project %CollectionCreated{} = collection, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    upsert_collection(multi, collection, ds_id)
  end

  project %CollectionUpdated{} = collection, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    upsert_collection(multi, collection, ds_id)
  end

  project %CollectionSchemaUpdated{} = collection, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Projectors.Schema.upsert_schema(collection, [is_collection: true, tenant: ds_id])
  end

  project %CollectionTargetAdded{} = collection, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Ecto.Multi.run(:get_collection, fn repo, _changes ->
      {:ok, repo.get(Collection, collection.id, prefix: ds_id)}
    end)
    |> Ecto.Multi.update(:collection, fn %{get_collection: s} ->
      Collection.changeset(s, %{
        targets: Enum.concat(s.targets || [], [collection.target])
      })
    end, prefix: ds_id)
  end

  project %CollectionTargetRemoved{} = collection, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Ecto.Multi.run(:get_collection, fn repo, _changes ->
      {:ok, repo.get(Collection, collection.id, prefix: ds_id)}
    end)
    |> Ecto.Multi.update(:collection, fn %{get_collection: s} ->
      Collection.changeset(s, %{
        targets: Enum.filter(s.targets || [], fn x -> x != collection.target end)
      })
    end, prefix: ds_id)
  end

  project %CollectionColorSet{} = collection, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Ecto.Multi.run(:get_collection, fn repo, _changes ->
      {:ok, repo.get(Collection, collection.id, prefix: ds_id)}
    end)
    |> Ecto.Multi.update(:collection, fn %{get_collection: s} ->
      Collection.changeset(s, %{
        color: collection.color
      })
    end, prefix: ds_id)
  end

  project %CollectionIsReadySet{} = collection, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Ecto.Multi.run(:get_collection, fn repo, _changes ->
      {:ok, repo.get(Collection, collection.id, prefix: ds_id)}
    end)
    |> Ecto.Multi.update(:collection, fn %{get_collection: s} ->
      Collection.changeset(s, %{
        is_ready: collection.is_ready
      })
    end, prefix: ds_id)
  end

  project %CollectionDeleted{} = collection, %{"ds_id" => ds_id} = _metadata, fn multi ->
    multi
    |> Ecto.Multi.run(:get_collection, fn repo, _changes ->
      {:ok, repo.get(Collection, collection.id, prefix: ds_id)}
    end)
    |> Ecto.Multi.delete(:delete, fn %{get_collection: s} -> s end)
  end

  defp upsert_collection(multi, collection, ds_id) do
    multi
    |> Ecto.Multi.run(:get_collection, fn repo, _changes ->
      {:ok, repo.get(Collection, collection.id, prefix: ds_id) || %Collection{id: collection.id} }
    end)
    |> Ecto.Multi.insert_or_update(:collection, fn %{get_collection: s} ->
      Collection.changeset(s, %{
        workspace: collection.workspace,
        uri: hd(collection.uri),
        type: collection.type,
        targets: collection.targets,
        position: collection.position,
        color: collection.color,
        is_ready: collection.is_ready
      })
    end, prefix: ds_id)
    |> Ecto.Multi.merge(fn %{collection: _} ->
      Ecto.Multi.new()
      |> Projectors.Schema.upsert_schema(collection, [is_collection: true, tenant: ds_id])
    end)
  end

end
