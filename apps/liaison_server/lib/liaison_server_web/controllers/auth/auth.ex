defmodule LiaisonServerWeb.Auth do
  import Plug.Conn
  import Phoenix.Controller
  import LiaisonServerWeb.Utils

  alias Landlord.Accounts

  @host get_external_host().host

  @max_age 60 * 60 * 24 * 30 # 30 days
  @remember_me_cookie "_mycelium_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Strict", secure: true]

  @csrf_cookie "_mycelium_csrf_token"
  @csrf_options [http_only: false, domain: "#{if @host != "localhost", do: "."}#{@host}", secure: true, same_site: "Strict"]

  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.
  """
  def log_in_user(conn, user, params \\ %{}, resp \\ %{}) do
    token = Accounts.generate_user_session_token(user)

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> write_csrf_token()
    |> maybe_write_remember_me_cookie(token, params)
    |> json(resp)
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_user(conn, resp \\ %{}) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_session_token(user_token)

    # Disconnect from websockets
    # LiaisonServerWeb.Endpoint.broadcast("user:${user.id}", "disconnect", %{})

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> delete_csrf_cookie()
    |> json(resp)
  end

  @doc """
  Authenticates the user by looking into the session
  and remember me token.
  """
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Accounts.get_user_by_session_token(user_token)

    assign(conn, :current_user, user)
  end

  @doc """
  Verify the X-CSRF-Token from a double submit cookie

  This is only used for the authentication routes, as no session
  is yet established for those.
  """
  def verify_double_submit(conn, _opts) do
    conn = fetch_cookies(conn)

    cookie = conn.cookies[@csrf_cookie]
    header = get_req_header(conn, "x-csrf-token")

    unless length(header) > 0 && cookie == hd(header) do
      conn
      |> resp(403, "Forbidden")
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(external: URI.to_string(get_external_host()) <> signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> maybe_store_return_to()
      |> redirect(external: URI.to_string(get_external_host()) <> "/login")
      |> halt()
    end
  end

  def write_csrf_token(conn) do
    token = get_csrf_token()

    conn
    |> put_session("_csrf_token", Process.get(:plug_unmasked_csrf_token))
    |> put_resp_cookie(@csrf_cookie, token, @csrf_options)
  end

  def delete_csrf_cookie(conn) do
    delete_csrf_token()
    delete_resp_cookie(conn, @csrf_cookie)
  end

  defp ensure_user_token(conn) do
    if user_token = get_session(conn, :user_token) do
      {user_token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if user_token = conn.cookies[@remember_me_cookie] do
        {user_token, put_session(conn, :user_token, user_token)}
      else
        {nil, conn}
      end
    end
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: "/"
end
