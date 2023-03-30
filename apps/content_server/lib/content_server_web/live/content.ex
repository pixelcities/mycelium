defmodule ContentServerWeb.Live.Content do
  use ContentServerWeb, :live_view
  on_mount ContentServerWeb.Live.UserAuth

  alias Landlord.Tenants
  alias ContentServerWeb.Live.Components

  import Core.Auth.Authorizer
  import Components.Script

  def render(assigns) do
    ~H"""
    <div>
      <.script external_host={@external_host} />

      <%= if @authorized do %>
        <.live_component module={Components.Content} id={@content_id} ds={@ds_id} is_public={@is_public} />
      <% end %>
    </div>
    """
  end

  def mount(%{"ds" => maybe_ds_id, "id" => id} = params, _session, socket) do
    case Tenants.get_data_space_by_handle(maybe_ds_id) do
      nil -> error(socket)
      ds ->
        case ContentServer.get_content!(id, tenant: ds.handle) do
          nil -> error(socket)
          content ->
            token = Map.get(params, "token")

            if token_is_valid?(token, content.access) do
              socket = assign(socket, :authorized, true)
              socket = assign(socket, :ds_id, ds.handle)
              socket = assign(socket, :external_host, URI.to_string(Core.Utils.Web.get_external_host()))
              socket = assign(socket, :is_public, (if is_public?(content.access), do: "1", else: "0"))
              socket = assign(socket, :content_id, id)

              {:ok, socket}
            else
              if token == nil do
                socket = assign(socket, :authorized, false)
                socket = assign(socket, :external_host, URI.to_string(Core.Utils.Web.get_external_host()))

                {:ok, socket}
              else
                error(socket)
              end
            end
        end
    end
  end

  defp error(socket) do
    {:ok, redirect(socket, to: "/error")}
  end

  defp token_is_valid?(token, access) do
    if is_public?(access) do
      true
    else
      case Phoenix.Token.verify(ContentServerWeb.Endpoint, "auth", token, max_age: 86400) do
        {:ok, user_id} -> authorized?(user_id, access)
        _ -> false
      end
    end
  end
end
