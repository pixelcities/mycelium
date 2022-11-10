defmodule ContentServer.Workflows.UpdateLiveContent do
  use Commanded.Event.Handler,
    name: __MODULE__,
    consistency: :strong

  alias Core.Events.{
    ContentUpdated,
    WidgetPublished
  }

  def handle(%ContentUpdated{} = _event, _metadata) do
    Enum.each(Registry.lookup(ContentServerWeb.Registry, "Content"), fn {pid, _} ->
      send(pid, :update)
    end)

    :ok
  end

  def handle(%WidgetPublished{} = _event, _metadata) do
    Enum.each(Registry.lookup(ContentServerWeb.Registry, "Content"), fn {pid, _} ->
      send(pid, :update)
    end)

    :ok
  end
end
