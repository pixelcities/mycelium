defmodule ContentServer.Workflows.UpdateLiveContent do
  use Commanded.Event.Handler,
    name: __MODULE__,
    consistency: :strong

  alias Core.Events.{
    ContentUpdated,
    WidgetPublished
  }
  alias ContentServerWeb.Live.Components

  import Core.Auth.Authorizer

  def handle(%ContentUpdated{} = event, _metadata) do
    Enum.each(Registry.lookup(ContentServerWeb.Registry, event.id), fn {pid, _} ->
      Phoenix.LiveView.send_update(pid, Components.Content, id: event.id, content: event.content, height: event.height)
    end)

    :ok
  end

  # TODO: this should instead be handled by dispatching UpdateContent
  def handle(%WidgetPublished{} = event, metadata) do
    ds_id = Map.get(metadata, "ds_id")
    content = ContentServer.get_content_by_widget_id(event.id, tenant: ds_id)

    # We can only handle public widgets ..
    if is_public?(event.access) do
      Enum.each(content, fn c ->

        # .. that are part of public pages
        if is_public?(c.access) do
          Enum.each(Registry.lookup(ContentServerWeb.Registry, c.id), fn {pid, _} ->
            Phoenix.LiveView.send_update(pid, Components.Content, id: c.id, content: event.content, height: event.height)
          end)
        end
      end)
    end

    :ok
  end
end
