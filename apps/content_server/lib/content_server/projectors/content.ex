defmodule ContentServer.Projectors.Content do
  use Commanded.Projections.Ecto,
    repo: ContentServer.Repo,
    name: "Projectors.Content",
    consistency: :strong

  @impl Commanded.Projections.Ecto
  def schema_prefix(_event, %{"ds_id" => ds_id} = _metadata), do: ds_id

  alias Core.Events.{
    ContentCreated,
    ContentUpdated,
    ContentDraftUpdated,
    ContentDeleted
  }
  alias ContentServer.Projections.Content

  project %ContentCreated{} = content, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    upsert_content(multi, content, ds_id)
  end

  project %ContentUpdated{} = content, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    upsert_content(multi, content, ds_id)
  end

  project %ContentDraftUpdated{} = content, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Ecto.Multi.run(:get_content, fn repo, _changes ->
      {:ok, repo.get(Content, content.id, prefix: ds_id)}
    end)
    |> Ecto.Multi.update(:content, fn %{get_content: s} ->
      Content.changeset(s, %{
        draft: content.draft
      })
    end, prefix: ds_id)
  end

  project %ContentDeleted{} = content, %{"ds_id" => ds_id} = _metadata, fn multi ->
    multi
    |> Ecto.Multi.run(:get_content, fn repo, _changes ->
      {:ok, repo.get(Content, content.id, prefix: ds_id)}
    end)
    |> Ecto.Multi.delete(:delete, fn %{get_content: s} -> s end)
  end

  defp upsert_content(multi, content, ds_id) do
    multi
    |> Ecto.Multi.run(:get_content, fn repo, _changes ->
      {:ok, repo.get(Content, content.id, prefix: ds_id) || %Content{id: content.id} }
    end)
    |> Ecto.Multi.insert_or_update(:content, fn %{get_content: s} ->
      Content.changeset(s, %{
        workspace: content.workspace,
        type: content.type,
        page_id: content.page_id,
        access: content.access,
        content: content.content,
        draft: content.draft,
        height: content.height,
        widget_id: content.widget_id
      })
    end, prefix: ds_id)
  end

end
