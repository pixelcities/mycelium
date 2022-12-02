defmodule MetaStore.Projectors.Widget do
  use Commanded.Projections.Ecto,
    repo: MetaStore.Repo,
    name: "Projectors.Widget",
    consistency: :strong

  @impl Commanded.Projections.Ecto
  def schema_prefix(_event, %{"ds_id" => ds_id} = _metadata), do: ds_id

  alias Core.Events.{
    WidgetCreated,
    WidgetUpdated,
    WidgetInputAdded,
    WidgetSettingPut,
    WidgetPublished,
    WidgetDeleted
  }
  alias MetaStore.Projections.Widget

  project %WidgetCreated{} = widget, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    upsert_widget(multi, widget, ds_id)
  end

  project %WidgetUpdated{} = widget, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    upsert_widget(multi, widget, ds_id)
  end

  project %WidgetInputAdded{} = widget, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Ecto.Multi.run(:get_widget, fn repo, _changes ->
      {:ok, repo.get(Widget, widget.id, prefix: ds_id)}
    end)
    |> Ecto.Multi.update(:widget, fn %{get_widget: s} ->
      Widget.changeset(s, %{
        collection: widget.collection
      })
    end, prefix: ds_id)
  end

  project %WidgetSettingPut{} = widget, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Ecto.Multi.run(:get_widget, fn repo, _changes ->
      {:ok, repo.get(Widget, widget.id, prefix: ds_id)}
    end)
    |> Ecto.Multi.update(:widget, fn %{get_widget: s} ->
      Widget.changeset(s, %{
        settings: Map.put(s.settings, widget.key, widget.value)
      })
    end, prefix: ds_id)
  end

  project %WidgetPublished{} = widget, metadata, fn multi ->
    ds_id = Map.get(metadata, "ds_id")

    multi
    |> Ecto.Multi.run(:get_widget, fn repo, _changes ->
      {:ok, repo.get(Widget, widget.id, prefix: ds_id)}
    end)
    |> Ecto.Multi.update(:widget, fn %{get_widget: s} ->
      Widget.changeset(s, %{
        access: s.access,
        content: s.content,
        height: s.height,
        is_published: s.is_published
      })
    end, prefix: ds_id)
  end

  project %WidgetDeleted{} = widget, %{"ds_id" => ds_id} = _metadata, fn multi ->
    multi
    |> Ecto.Multi.run(:get_widget, fn repo, _changes ->
      {:ok, repo.get(Widget, widget.id, prefix: ds_id)}
    end)
    |> Ecto.Multi.delete(:delete, fn %{get_widget: s} -> s end)
  end

  defp upsert_widget(multi, widget, ds_id) do
    multi
    |> Ecto.Multi.run(:get_widget, fn repo, _changes ->
      {:ok, repo.get(Widget, widget.id, prefix: ds_id) || %Widget{id: widget.id} }
    end)
    |> Ecto.Multi.insert_or_update(:widget, fn %{get_widget: s} ->
      Widget.changeset(s, %{
        workspace: widget.workspace,
        type: widget.type,
        position: widget.position,
        color: widget.color,
        is_ready: widget.is_ready,
        collection: widget.collection,
        settings: widget.settings,
        access: widget.access,
        content: widget.content,
        height: widget.height,
        is_published: widget.is_published
      })
    end, prefix: ds_id)
  end

end
