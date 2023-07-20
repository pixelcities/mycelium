defmodule ContentServer.Projectors.Page do
  use Commanded.Projections.Ecto,
    repo: ContentServer.Repo,
    name: "Projectors.Page",
    consistency: :strong

  @impl Commanded.Projections.Ecto
  def schema_prefix(_event, %{"ds_id" => ds_id} = _metadata), do: ds_id

  alias Core.Events.{
    PageCreated,
    PageUpdated,
    PageOrderSet,
    PageDeleted
  }
  alias ContentServer.Projections.Page

  project %PageCreated{} = page, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    upsert_page(multi, page, ds_id)
  end

  project %PageUpdated{} = page, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    upsert_page(multi, page, ds_id)
  end

  project %PageOrderSet{} = page, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Ecto.Multi.run(:get_page, fn repo, _changes ->
      {:ok, repo.get(Page, page.id, prefix: ds_id)}
    end)
    |> Ecto.Multi.update(:page, fn %{get_page: s} ->
      Page.changeset(s, %{
        content_order: page.content_order
      })
    end, prefix: ds_id)
  end

  project %PageDeleted{} = page, %{"ds_id" => ds_id} = _metadata, fn multi ->
    multi
    |> Ecto.Multi.run(:get_page, fn repo, _changes ->
      {:ok, repo.get(Page, page.id, prefix: ds_id)}
    end)
    |> Ecto.Multi.delete(:delete, fn %{get_page: s} -> s end)
  end

  @impl true
  def error({:error, error}, _event, _failure_context) do
    Logger.error(fn -> "Page projector is skipping event due to:" <> inspect(error) end)

    :skip
  end

  defp upsert_page(multi, page, ds_id) do
    multi
    |> Ecto.Multi.run(:get_page, fn repo, _changes ->
      {:ok, repo.get(Page, page.id, prefix: ds_id) || %Page{id: page.id} }
    end)
    |> Ecto.Multi.insert_or_update(:page, fn %{get_page: s} ->
      Page.changeset(s, %{
        workspace: page.workspace,
        access: page.access,
        key_id: page.key_id
      })
    end, prefix: ds_id)
  end

end
