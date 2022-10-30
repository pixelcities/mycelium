defmodule ContentServerWeb.Live.UserAuth do
  import Phoenix.LiveView

  def on_mount(:default, params, _session, socket) do
    socket = assign_new(socket, :token, fn ->
      Map.get(params, "token")
    end)

    if authorized?(socket.assigns.token) do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/error")}
    end
  end

  defp authorized?(_token), do: true
end


