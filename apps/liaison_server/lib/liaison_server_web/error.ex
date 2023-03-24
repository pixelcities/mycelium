defmodule LiaisonServerWeb.ErrorView do
  use LiaisonServerWeb, :controller

  def render("404.json", %{conn: conn} = _assigns) do
    conn
    |> put_status(404)
    |> json(%{error: "Not Found"})
  end

  def render(_, %{conn: conn} = _assigns) do
    conn
    |> put_status(500)
    |> json(%{error: "Internal Server Error"})
  end
end

