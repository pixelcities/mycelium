defmodule LiaisonServerWeb.DataSpaceChannel do
  use LiaisonServerWeb, :channel

  require Logger

  alias LiaisonServerWeb.Tracker
  alias Landlord.Tenants
  alias LiaisonServerWeb.Registry.UserDataSpaces


  @impl true
  def join("ds:" <> handle, payload, socket) do
    user = socket.assigns.current_user
    maybe_ds_id = Tenants.to_atom(user, handle)

    if authorized?(user, maybe_ds_id, payload) do
      {:ok, ds_id} = maybe_ds_id
      socket = assign(socket, :current_ds, ds_id)

      # Notify the UserChannel about the ds
      [{pid, _}] = Registry.lookup(UserDataSpaces, user.id)
      send(pid, {:set_data_space, ds_id})

      send(self(), :after_join)

      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} = Phoenix.Tracker.track(Tracker, self(), "ds:" <> Atom.to_string(socket.assigns.current_ds), socket.assigns.current_user.id, %{
      ds_id: socket.assigns.current_ds,
      online_at: inspect(System.system_time(:second))
    })

    {:noreply, socket}
  end


  # Add authorization logic here as required.
  defp authorized?(user, _ds_id, _payload) when user.confirmed_at == nil, do: false
  defp authorized?(_user, {:ok, ds_id}, _payload) when is_atom(ds_id), do: true
  defp authorized?(_user, _ds_id, _payload), do: false

end
