defmodule ContentServer.Workflows.UpdateLiveContent do
  use Commanded.Event.Handler,
    name: __MODULE__,
    consistency: :strong

  alias Core.Events.{
    ContentUpdated,
    WidgetPublished
  }
  alias ContentServerWeb.Live.Components

  def handle(%ContentUpdated{} = event, _metadata) do
    Enum.each(Registry.lookup(ContentServerWeb.Registry, event.id), fn {pid, _} ->
      Phoenix.LiveView.send_update(pid, Components.Content, id: event.id, content: event.content)
    end)

    :ok
  end

  def handle(%WidgetPublished{} = event, metadata) do
    ds_id = Map.get(metadata, "ds_id")
    content = ContentServer.get_content_by_widget_id(event.id, tenant: ds_id)

    Enum.each(content, fn c ->
      Enum.each(Registry.lookup(ContentServerWeb.Registry, c.id), fn {pid, _} ->
        Phoenix.LiveView.send_update(pid, Components.Content, id: event.id, content: event.content)
      end)
    end)

    :ok
  end
end
