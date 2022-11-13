defmodule ContentServerWeb.Live.Page do
  use ContentServerWeb, :live_view
  on_mount ContentServerWeb.Live.UserAuth

  alias ContentServerWeb.Live.Components

  import Core.Auth.Authorizer
  import Components.Script

  def render(assigns) do
    ~H"""
    <div>
      <.script external_host={@external_host} />
      <%= for content_id <- @content_ids do %>
        <.live_component module={Components.Content} id={content_id} ds={@ds_id} is_public={@is_public} />
      <% end %>
    </div>
    """
  end

  def mount(%{"ds" => ds_id, "id" => id}, _session, socket) do
    page = ContentServer.get_page!(id, tenant: ds_id)

    # TODO: Get some session info
    if authorized?(nil, page.access) do
      socket = assign(socket, :ds_id, ds_id)
      socket = assign(socket, :external_host, URI.to_string(Core.Utils.Web.get_external_host()))
      socket = assign(socket, :is_public, (if is_public?(page.access), do: "1", else: "0"))
      socket = assign(socket, :content_ids, Enum.map(page.content, fn content -> content.id end))

      {:ok, socket}
    else
      {:ok, redirect(socket, to: "/error")}
    end
  end
end
