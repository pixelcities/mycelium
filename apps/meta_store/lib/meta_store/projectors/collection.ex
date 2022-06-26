defmodule MetaStore.Projectors.Collection do
  use Commanded.Projections.Ecto,
    repo: MetaStore.Repo,
    name: "Projectors.Collection",
    consistency: :strong

  alias Core.Events.{CollectionCreated, CollectionUpdated, CollectionSchemaUpdated, CollectionIsReadySet}
  alias MetaStore.Projections.Collection
  alias MetaStore.Projectors

  project %CollectionCreated{} = collection, _metadata, fn multi ->
    upsert_collection(multi, collection)
  end

  project %CollectionUpdated{} = collection, _metadata, fn multi ->
    upsert_collection(multi, collection)
  end

  project %CollectionSchemaUpdated{} = collection, _metadata, fn multi ->
    multi
    |> Projectors.Schema.upsert_schema(collection, [is_collection: true])
  end

  project %CollectionIsReadySet{} = collection, _metadata, fn multi ->
    multi
    |> Ecto.Multi.run(:get_collection, fn repo, _changes ->
      {:ok, repo.get(Collection, collection.id)}
    end)
    |> Ecto.Multi.update(:collection, fn %{get_collection: s} ->
      Collection.changeset(s, %{
        is_ready: collection.is_ready
      })
    end)
  end

  defp upsert_collection(multi, collection) do
    multi
    |> Ecto.Multi.run(:get_collection, fn repo, _changes ->
      {:ok, repo.get(Collection, collection.id) || %Collection{id: collection.id} }
    end)
    |> Ecto.Multi.insert_or_update(:collection, fn %{get_collection: s} ->
      Collection.changeset(s, %{
        workspace: collection.workspace,
        uri: collection.uri,
        type: collection.type,
        targets: collection.targets,
        position: collection.position,
        color: collection.color,
        is_ready: collection.is_ready
      })
    end)
    |> Ecto.Multi.merge(fn %{collection: _} ->
      Ecto.Multi.new()
      |> Projectors.Schema.upsert_schema(collection, [is_collection: true])
    end)
  end

end
