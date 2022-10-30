defmodule ContentServerWeb.Live.Content do
  use ContentServerWeb, :live_view
  on_mount ContentServerWeb.Live.UserAuth

  def mount(%{"ds" => ds_id, "id" => id}, _session, socket) do
    if authorized?(socket.assigns.token) do
      content = ContentServer.get_content!(id, tenant: ds_id)

      if content.access == "public" do
        socket = assign(socket, :ds_id, ds_id)
        socket = assign(socket, :content_id, content.id)
        socket = assign(socket, :content, content.content)

        {:ok, socket}
      else
        {:ok, redirect(socket, to: "/error")}
      end
    else
      {:ok, redirect(socket, to: "/error")}
    end
  end

  def handle_info(:update, socket) do
    content = ContentServer.get_content!(socket.assigns.content_id, tenant: socket.assigns.ds_id)

    if content do
      {:noreply, assign(socket, :content, content)}
    else
      {:noreply, socket}
    end
  end

  defp authorized?(_token), do: true
end
