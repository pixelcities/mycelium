defmodule LiaisonServerWeb.DataSpaceChannel do
  use LiaisonServerWeb, :channel

  require Logger

  alias LiaisonServerWeb.Tracker

  @impl true
  def join("ds:" <> ds_id, payload, socket) do
    user = socket.assigns.current_user

    send(self(), :after_join)

    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do
    ds_id = "1"

    {:ok, _} = Phoenix.Tracker.track(Tracker, self(), "ds:" <> ds_id, socket.assigns.current_user.id, %{
      online_at: inspect(System.system_time(:second))
    })

    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end

end
