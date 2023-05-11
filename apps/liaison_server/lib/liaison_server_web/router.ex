defmodule LiaisonServerWeb.Router do
  use LiaisonServerWeb, :router
  use Plug.ErrorHandler

  require Logger

  import LiaisonServerWeb.Auth

  pipeline :common do
    plug RemoteIp,
      headers: ~w[x-forwarded-for]
    plug :fetch_session
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :auth do
    plug :common
    plug :accepts, ["json"]
    plug :put_format, "json"
  end

  pipeline :api do
    plug :common
    plug :accepts, ["json"]
    plug :put_format, "json"
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
    post "/pagetoken", UserProfileController, :pagetoken
    post "/datatokens", UserProfileController, :datatokens
    get "/:id", UserProfileController, :get_user
    put "/profile", UserProfileController, :update_user
    put "/profile/confirm_email/:token/:rotation_token", UserProfileController, :confirm_email
  end

  ## Data space routes

  scope "/spaces", LiaisonServerWeb.DataSpaces do
    pipe_through [:api, :require_authenticated_user]

    get "/", DataSpaceController, :list_data_spaces
    get "/:handle", DataSpaceController, :get_data_space
    post "/:handle/invite", DataSpaceController, :invite_to_data_space
    post "/:handle/cancel_invite", DataSpaceController, :cancel_invite
    post "/:handle/confirm_member", DataSpaceController, :confirm_member
    delete "/:handle/leave", DataSpaceController, :leave_data_space
    put "/accept_invite/:token", DataSpaceController, :accept_invite
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

  ## Subscription routes

  scope "/subscriptions", LiaisonServerWeb.Subscriptions do
    post "/webhook", PaddleController, :webhook
  end


  defp handle_errors(conn, %{reason: %Phoenix.Router.NoRouteError{message: message}}) do
    conn
    |> json(%{error: Regex.replace(~r/ +\(.*\)$/, message, "")})
    |> halt()
  end

  defp handle_errors(conn, %{reason: %Plug.CSRFProtection.InvalidCSRFTokenError{message: message}}) do
    conn |> json(%{error: message}) |> halt()
  end

  defp handle_errors(conn, %{reason: %Phoenix.ActionClauseError{}}) do
    conn |> json(%{error: "Bad request"}) |> halt()
  end

  defp handle_errors(conn, reason) do
    Logger.error("Unhandled error in router: " <> Exception.format(:error, reason))

    conn |> json(%{error: "Internal server error"}) |> halt()
  end
end
