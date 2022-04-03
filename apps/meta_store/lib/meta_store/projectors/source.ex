defmodule MetaStore.Projectors.Source do
  use Commanded.Projections.Ecto,
    repo: MetaStore.Repo,
    name: "Projectors.Source",
    consistency: :strong

  alias Core.Events.{SourceCreated, SourceUpdated}
  alias MetaStore.Projections.{Source, Schema, Column, Share}

  project %SourceCreated{} = source, _metadata, fn multi ->
    upsert_source(source, multi)
  end

  # TODO: This does not always trigger the multi? (event number?)
  project %SourceUpdated{} = source, _metadata, fn multi ->
    upsert_source(source, multi)
  end


  defp upsert_source(source, multi) do
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
    |> Ecto.Multi.run(:schema, fn repo, changes ->
      schema =
        case repo.get(Schema, source.schema.id) do
          nil -> %Schema{id: source.schema.id}
          schema -> schema
        end
        |> Schema.changeset(%{key_id: source.schema.key_id, column_order: source.schema.column_order, source_id: changes.source.id})
        |> repo.insert_or_update!

      shares = Enum.map(source.schema.shares, fn share ->
        repo.insert!(%Share{principal: share.principal, type: share.type}, on_conflict: {:replace_all_except, [:id]}, conflict_target: :id)
      end)

      schema
      |> repo.preload(:shares)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:shares, shares)
      |> repo.update!

      {:ok, schema}
    end)
    |> Ecto.Multi.run(:columns, fn repo, changes ->
      columns = Enum.map(source.schema.columns, fn c ->
        column =
          case repo.get(Column, c.id) do
            nil -> %Column{id: c.id}
            column -> column
          end
          |> Column.changeset(%{key_id: c.key_id, schema_id: changes.schema.id})
          |> repo.insert_or_update!

        shares = Enum.map(c.shares, fn share ->
          repo.insert!(%Share{principal: share.principal, type: share.type}, on_conflict: {:replace_all_except, [:id]}, conflict_target: :id)
        end)

        column
        |> repo.preload(:shares)
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:shares, shares)
        |> repo.update!
      end)

      {:ok, columns}
    end)
  end

end
