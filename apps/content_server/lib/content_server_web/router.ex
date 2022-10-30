defmodule ContentServerWeb.Router do
  use ContentServerWeb, :router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ContentServerWeb.LayoutView, :root}
    plug :protect_from_forgery
    # plug :put_secure_browser_headers
  end

  scope "/", ContentServerWeb do
    get "/error", ErrorController, :index
  end

  ## User content routes

  scope "/content", ContentServerWeb.Live do
    pipe_through [:browser]

    live "/:ds/:id", Content
  end

end
