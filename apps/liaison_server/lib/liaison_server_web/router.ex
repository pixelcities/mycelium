defmodule LiaisonServerWeb.Router do
  use LiaisonServerWeb, :router

  import LiaisonServerWeb.Auth

  pipeline :api do
    plug RemoteIp,
      headers: ~w[x-real-ip]
    plug :accepts, ["json"]
    plug :fetch_session
    # plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :gatekeeper do
    plug Hammer.Plug, [
      rate_limit: {"default", 60_000, 10},
    ]
  end

  ## Authentication routes

  scope "/auth/local", LiaisonServerWeb.Auth.Local do
    pipe_through [:api, :gatekeeper, :redirect_if_user_is_authenticated]

    post "/register", UserRegistrationController, :register_user
    post "/login", UserSessionController, :login_user
    post "/reset_password", UserResetPasswordController, :reset_user_password
    put "/reset_password/:token", UserResetPasswordController, :confirm_password_reset
  end

  scope "/auth/local", LiaisonServerWeb.Auth.Local do
    pipe_through [:api, :gatekeeper]

    delete "/logout", UserSessionController, :logout_user
    post "/confirm", UserConfirmationController, :request_confirm_registration
    put "/confirm/:token", UserConfirmationController, :confirm_registration
  end

  scope "/users", LiaisonServerWeb.Users do
    pipe_through [:api, :require_authenticated_user]

    get "/token", UserProfileController, :token
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

    get "/", KeyController, :list_keys
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
