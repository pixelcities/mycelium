defmodule ContentServerWeb.Router do
  use ContentServerWeb, :router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ContentServerWeb.LayoutView, :root}
    plug :protect_from_forgery
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ContentServerWeb do
    get "/error", ErrorController, :index
  end

  ## User content routes

  scope "/info", ContentServerWeb do
    get "/:ds/:id", PageController, :get_info
  end

  scope "/pages", ContentServerWeb.Live do
    pipe_through [:browser]

    live "/content/:ds/:id", Content
    live "/:ds/:id", Page
  end

end
