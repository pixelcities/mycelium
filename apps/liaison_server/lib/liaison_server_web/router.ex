defmodule LiaisonServerWeb.Router do
  use LiaisonServerWeb, :router

  import LiaisonServerWeb.Auth

  pipeline :common do
    plug RemoteIp,
      headers: ~w[x-real-ip]
    plug :fetch_session
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :auth do
    plug :common
    plug :accepts, ["json"]
  end

  pipeline :api do
    plug :common
    plug :accepts, ["json"]
    plug :protect_from_forgery
  end

  pipeline :browser do
    plug :common
  end

  pipeline :gatekeeper do
    plug Hammer.Plug, [
      rate_limit: {"default", 60_000, 10},
    ]
  end

  ## Authentication routes

  scope "/auth/local", LiaisonServerWeb.Auth.Local do
    pipe_through [:auth, :gatekeeper, :verify_double_submit, :redirect_if_user_is_authenticated]

    post "/register", UserRegistrationController, :register_user
    post "/login", UserSessionController, :login_user
  end

  scope "/auth/local", LiaisonServerWeb.Auth.Local do
    pipe_through [:api, :gatekeeper]

    delete "/logout", UserSessionController, :logout_user
    post "/confirm", UserConfirmationController, :request_confirm_registration
    put "/confirm/:token", UserConfirmationController, :confirm_registration
  end

  scope "/users", LiaisonServerWeb.Users do
    pipe_through [:api, :require_authenticated_user]

    post "/token", UserProfileController, :token
    post "/datatokens", UserProfileController, :datatokens
    get "/:id", UserProfileController, :get_user
    put "/profile", UserProfileController, :update_user
    put "/profile/confirm_email/:token", UserProfileController, :confirm_email
  end

  ## Data space routes

  scope "/spaces", LiaisonServerWeb.DataSpaces do
    pipe_through [:api, :require_authenticated_user]

    get "/", DataSpaceController, :list_data_spaces
    get "/:handle", DataSpaceController, :get_data_space
  end

  ## KeyStore routes

  scope "/keys", LiaisonServerWeb.KeyStore do
    pipe_through [:api, :require_authenticated_user]

    get "/", KeyController, :get_keys
    post "/", KeyController, :create_key
    post "/rotate", KeyController, :rotate_keys

    get "/manifest", ManifestController, :get_manifest
    put "/manifest", ManifestController, :put_manifest

    get "/:id", KeyController, :get_key
    put "/:id", KeyController, :put_key
    delete "/:id", KeyController, :delete_key
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
