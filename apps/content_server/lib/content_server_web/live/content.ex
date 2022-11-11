defmodule ContentServerWeb.Live.Content do
  use ContentServerWeb, :live_view
  on_mount ContentServerWeb.Live.UserAuth

  import Core.Auth.Authorizer

  def render(assigns) do
    ~H"""
    <div>
      <iframe id={@content_id} sandbox width="100%" height="100%" frameborder="0" data={@content} public={@is_public} phx-hook="Render" />
      <script type="module">
        import { DOMPurify } from "/assets/vendor.js"

        const worker = new Worker("/assets/worker.js")
        worker.onmessage = (e) => {
          if (e.data.action === "keySaved") {
            const frames = document.getElementsByTagName("iframe")
            for (const frame of frames) {
              render(frame.id)
            }

          } else if (e.data.action === "render") {
            const { id, data } = e.data
            const iframe = document.getElementById(id)
            iframe.srcdoc = DOMPurify.sanitize(data)
          }
        }

        window.addEventListener("message", (e) => {
          if (e.origin === "<%= @external_host %>") {
            worker.postMessage({ action: "saveKey", payload: e.data })
          }
        })

        window.render = (id) => {
          const iframe = document.getElementById(id)
          const data = iframe.getAttribute("data")
          const isPublic = iframe.getAttribute("public")

          worker.postMessage({ action: "render", payload: { id, data, isPublic } })
        }
      </script>
    </div>
    """
  end

  def mount(%{"ds" => ds_id, "id" => id}, _session, socket) do
    Registry.register(ContentServerWeb.Registry, "Content", nil)

    if authorized?(socket.assigns.token) do
      content = ContentServer.get_content!(id, tenant: ds_id)

      # TODO: Get some session info from token
      if authorized?(nil, content.access) do
        socket = assign(socket, :ds_id, ds_id)
        socket = assign(socket, :is_public, (if is_public?(content.access), do: "1", else: "0"))
        socket = assign(socket, :external_host, URI.to_string(Core.Utils.Web.get_external_host()))

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
      {:noreply, assign(socket, :content, content.content)}
    else
      {:noreply, socket}
    end
  end

  defp authorized?(_token), do: true
end
