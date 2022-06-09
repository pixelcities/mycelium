defmodule LiaisonServerWeb.Router do
  use LiaisonServerWeb, :router

  import LiaisonServerWeb.Auth

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    # plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  ## Authentication routes

  scope "/auth/local", LiaisonServerWeb.Auth.Local do
    pipe_through [:api, :redirect_if_user_is_authenticated]

    post "/register", UserRegistrationController, :create
    post "/login", UserSessionController, :create
    post "/reset_password", UserResetPasswordController, :create
    put "/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/auth/local", LiaisonServerWeb.Auth.Local do
    pipe_through [:api]

    delete "/logout", UserSessionController, :delete
    post "/confirm", UserConfirmationController, :create
    put "/confirm/:token", UserConfirmationController, :confirm
  end

  scope "/users", LiaisonServerWeb.Users do
    pipe_through [:api, :require_authenticated_user]

    get "/token", UserProfileController, :token
    post "/datatokens", UserProfileController, :datatokens
    get "/:id", UserProfileController, :get
    put "/profile", UserProfileController, :update
    put "/profile/confirm_email/:token", UserProfileController, :confirm_email
  end

  ## Data space routes

  scope "/spaces", LiaisonServerWeb.DataSpaces do
    pipe_through [:api, :require_authenticated_user]

    get "/", DataSpaceController, :list
    get "/:handle", DataSpaceController, :get
  end

  ## KeyStore routes

  scope "/keys", LiaisonServerWeb.KeyStore do
    pipe_through [:api, :require_authenticated_user]

    get "/", KeyController, :list
    post "/", KeyController, :create
    post "/rotate", KeyController, :rotate

    get "/manifest", ManifestController, :get
    put "/manifest", ManifestController, :put

    get "/:id", KeyController, :get
    put "/:id", KeyController, :put
    delete "/:id", KeyController, :delete
  end

  ## KeyX routes

  scope "/protocol", LiaisonServerWeb.Protocol do
    pipe_through [:api, :require_authenticated_user]

    post "/bundles", ProtocolController, :create_bundle
    get "/bundles", ProtocolController, :get_latest_bundle
    get "/bundles/:user_id", ProtocolController, :get_bundle
    delete "/bundles/:user_id/:bundle_id", ProtocolController, :delete_bundle

    get "/sync", ProtocolController, :get_state
    put "/sync", ProtocolController, :put_state
  end

end
