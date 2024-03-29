defmodule MetaStore.Projectors.Schema do
  alias MetaStore.Projections.{Schema, Column, Share}

  def upsert_schema(multi, input, opts \\ []) do
    tenant = Keyword.get(opts, :tenant)
    is_source = Keyword.get(opts, :is_source, false)
    is_collection = Keyword.get(opts, :is_collection, false)

    if !((is_source || is_collection) && !(is_source && is_collection)) do
      raise "Schema should belong to either a source or collection"
    end

    case input.schema do
      nil -> multi
      _ -> multi
        |> Ecto.Multi.run(:schema, fn repo, _ ->
          schema =
            case repo.get(Schema, input.schema.id, prefix: tenant) do
              nil -> %Schema{id: input.schema.id}
              schema -> schema
            end
            |> schema_changeset(input.schema.key_id, input.schema.column_order, input.schema.tag, input.id, is_source)
            |> repo.insert_or_update!(prefix: tenant)

          shares = Enum.map(input.schema.shares, fn share ->
            repo.insert!(%Share{principal: share.principal, type: share.type}, on_conflict: {:replace_all_except, [:id]}, conflict_target: :id, prefix: tenant)
          end)

          schema
          |> repo.preload(:shares, prefix: tenant)
          |> Ecto.Changeset.change()
          |> Ecto.Changeset.put_assoc(:shares, shares) # TODO: (RuntimeError) you are attempting to change relation :shares of MetaStore.Projections.Schema but the `:on_replace` option of this relation is set to `:raise`
          |> repo.update!(prefix: tenant)

          {:ok, schema}
        end)
        |> Ecto.Multi.run(:columns, fn repo, changes ->
          columns = Enum.map(input.schema.columns, fn c ->
            column =
              case repo.get(Column, c.id, prefix: tenant) do
                nil -> %Column{id: c.id}
                column -> column
              end
              |> Column.changeset(%{concept_id: c.concept_id, key_id: c.key_id, lineage: c.lineage, schema_id: changes.schema.id})
              |> repo.insert_or_update!(prefix: tenant)

            shares = Enum.map(c.shares, fn share ->
              repo.insert!(%Share{principal: share.principal, type: share.type}, on_conflict: {:replace_all_except, [:id]}, conflict_target: :id, prefix: tenant)
            end)

            column
            |> repo.preload(:shares, prefix: tenant)
            |> Ecto.Changeset.change()
            |> Ecto.Changeset.put_assoc(:shares, shares)
            |> repo.update!(prefix: tenant)
          end)

          {:ok, columns}
        end)
    end
  end

  defp schema_changeset(schema, key_id, column_order, tag, input_id, is_source) do
    if is_source do
      Schema.changeset(schema, %{key_id: key_id, column_order: column_order, tag: tag, source_id: input_id, collection_id: nil})
    else
      Schema.changeset(schema, %{key_id: key_id, column_order: column_order, tag: tag, collection_id: input_id, source_id: nil})
    end
  end

end
