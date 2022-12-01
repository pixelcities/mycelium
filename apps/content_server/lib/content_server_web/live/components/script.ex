defmodule ContentServerWeb.Live.Components.Script do
  use Phoenix.Component

  def script(assigns) do
    ~H"""
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
          iframe.srcdoc = `
            <html>
              <head>
                <link rel="stylesheet" href="/assets/app.css">
              </head>
              <body>
                <div class="content">
                  ${DOMPurify.sanitize(data)}
                </div>
              </body>
            </html>
          `
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
    """
  end
end
