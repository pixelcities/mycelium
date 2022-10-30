defmodule ContentServerWeb.ErrorController do
  use ContentServerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
