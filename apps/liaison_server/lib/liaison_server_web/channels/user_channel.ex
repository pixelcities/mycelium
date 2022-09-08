defmodule LiaisonServerWeb.UserChannel do
  use LiaisonServerWeb, :channel

  require Logger

  alias LiaisonServerWeb.Tracker

  @impl true
  def join("user:" <> user_id, payload, socket) do
    user = socket.assigns.current_user

    if user_id == user.id and authorized?(user, payload) do
      send(self(), :after_join)

      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    user_id = socket.assigns.current_user.id
    {:ok, _} = Phoenix.Tracker.track(Tracker, self(), "user:" <> user_id, user_id, %{
      ds_id: Map.get(socket.assigns, :current_ds),
      online_at: inspect(System.system_time(:second))
    })

    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(user, _payload) when user.confirmed_at == nil, do: false
  defp authorized?(_user, _payload), do: true

end
