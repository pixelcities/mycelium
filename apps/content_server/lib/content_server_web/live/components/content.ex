defmodule ContentServerWeb.Live.Components.Content do
  use ContentServerWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <iframe id={@content_id} sandbox width="100%" height="100%" frameborder="0" data={@content} public={@is_public} phx-hook="Render" />
    </div>
    """
  end

  def update(%{:ds => ds_id, :id => id, :is_public => is_public} = _assigns, socket) do
    Registry.register(ContentServerWeb.Registry, id, nil)

    content = ContentServer.get_content!(id, tenant: ds_id)

    socket = assign(socket, :ds_id, ds_id)
    socket = assign(socket, :is_public, is_public)
    socket = assign(socket, :content_id, content.id)
    socket = assign(socket, :content, content.content)

    {:ok, socket}
  end

  def update(%{:content => content} = _assigns, socket) do
    {:ok, assign(socket, :content, content)}
  end
 end
