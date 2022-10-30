defmodule ContentServer.Workflows.UpdateLiveContent do
  use Commanded.Event.Handler,
    name: __MODULE__,
    consistency: :strong

  alias Core.Events.{
    ContentUpdated,
    WidgetPublished
  }

  # TODO: Call live process
  def handle(%ContentUpdated{} = _event, _metadata) do
    :ok
  end

  def handle(%WidgetPublished{} = _event, _metadata) do
    :ok
  end
end
