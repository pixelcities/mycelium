defmodule ContentServerWeb.PageController do
  use ContentServerWeb, :controller

  import Core.Auth.Authorizer
  alias Landlord.Tenants

  @doc """
  Returns some very basic info

  Mostly used to allow the proper iframe height
  """
  def get_info(conn, %{"ds" => maybe_ds_id, "id" => id}) do
    case Tenants.get_data_space_by_handle(maybe_ds_id) do
      nil -> not_found(conn)
      ds ->
        case ContentServer.get_page!(id, tenant: ds.handle) do
          nil -> not_found(conn)
          page ->
            if is_public?(page.access) do
              padding = 7
              content = ContentServer.get_content_by_page_id(id, tenant: ds.handle)
              height = Enum.sum(Enum.map(content, fn c -> (c.height || 0) + padding end))

              json(conn, %{
                "height" => height
              })
            else
              not_found(conn)
            end
        end
    end
  end

  defp not_found(conn) do
    conn
    |> put_status(404)
    |> json(%{"status" => "Not Found"})
  end
end
