defmodule ContentServerWeb.Live.Page do
  use ContentServerWeb, :live_view

  alias Landlord.Tenants
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

  def mount(%{"ds" => maybe_ds_id, "id" => id}, _session, socket) do
    case Tenants.get_data_space_by_handle(maybe_ds_id) do
      nil -> error(socket)
      ds ->
        case ContentServer.get_page!(id, tenant: ds.handle) do
          nil -> error(socket)
          page ->
            Registry.register(ContentServerWeb.Registry, id, nil)
            content_ids = get_content_ids(page)

            # Pages are public
            if is_public?(page.access) do
              socket = assign(socket, :id, id)
              socket = assign(socket, :ds_id, ds.handle)
              socket = assign(socket, :external_host, URI.to_string(Core.Utils.Web.get_external_host()))
              socket = assign(socket, :is_public, (if is_public?(page.access), do: "1", else: "0"))
              socket = assign(socket, :content_ids, content_ids)

              {:ok, socket}
            else
              error(socket)
            end
        end
    end
  end

  def handle_info(:update, socket) do
    page = ContentServer.get_page!(socket.assigns.id, tenant: socket.assigns.ds_id)
    content_ids = get_content_ids(page)

    {:noreply, assign(socket, :content_ids, content_ids)}
  end

  defp error(socket) do
    {:ok, redirect(socket, to: "/error")}
  end

  defp get_content_ids(page) do
    page.content
      |> Enum.sort_by(fn c -> c.inserted_at end)
      |> Enum.sort_by(fn c -> Enum.find_index(page.content_order || [], &(&1 == c.id)) end)
      |> Enum.map(fn c -> c.id end)
  end
end
