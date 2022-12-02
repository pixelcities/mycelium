defmodule ContentServerWeb.PageController do
  use ContentServerWeb, :controller

  import Core.Auth.Authorizer

  @doc """
  Returns some very basic info

  Mostly used to allow the proper iframe height
  """
  def get_info(conn, %{"ds" => ds_id, "id" => id}) do
    page = ContentServer.get_page!(id, tenant: ds_id)

    if page != nil and authorized?(nil, page.access) do
      content = ContentServer.get_content_by_page_id(id, tenant: ds_id)
      height = Enum.sum(Enum.map(content, fn c -> c.height || 0 end))

      json(conn, %{
        "height" => height
      })

    else
      conn
      |> put_status(404)
      |> json(%{"status" => "Not Found"})
    end
  end
end
