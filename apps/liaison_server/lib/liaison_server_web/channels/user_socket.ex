defmodule LiaisonServerWeb.UserSocket do
  use Phoenix.Socket

  alias Landlord.Accounts

  channel "user:*", LiaisonServerWeb.UserChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case Phoenix.Token.verify(socket, "auth", token, max_age: 86400) do
      {:ok, user_id} ->
        socket = assign(socket, :current_user, Accounts.get_user!(user_id))
        {:ok, socket}
      {:error, _} ->
        :error
    end
  end

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.current_user.id}"
end
