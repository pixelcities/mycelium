defmodule LiaisonServerWeb.DataSpaceChannel do
  use LiaisonServerWeb, :channel

  require Logger

  alias LiaisonServerWeb.Tracker

  @impl true
  def join("ds:" <> ds_id, payload, socket) do
    user = socket.assigns.current_user

    if authorized?(user, payload) do
      send(self(), :after_join)

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
  defp authorized?(user, _payload) when user.confirmed_at, do: true
  defp authorized?(_user, _payload), do: false


end
