defmodule RecaptchaWeb.SessionController do
  alias CsrfPlus.UserAccess
  use RecaptchaWeb, :controller

  require Logger

  @csrf_key "_csrf_token"

  def sync(conn, _params) do
    show_ip_address(conn)

    conn
    |> put_cookie_token()
    |> put_header_token()
    |> put_status(:no_content)
    |> put_secure_browser_headers()
    |> text("")
  end

  def csrf_key, do: @csrf_key

  defp show_ip_address(conn) do
    Logger.info("IP address: #{inspect(conn.remote_ip)}")

    get_req_header(conn, "x-real-ip")
    |> IO.inspect(label: "x-real-ip")

    get_req_header(conn, "x-forwarded-for")
    |> IO.inspect(label: "x-forwarded-for")
  end

  defp put_cookie_token(conn) do
    case get_session(conn, :access_id) do
      nil ->
        {token, signed_token} = CsrfPlus.Token.generate()

        Logger.info(
          "Creating new csrf token: #{inspect(token)} with signed: #{inspect(signed_token)}"
        )

        access_id = UUID.uuid4()
        CsrfPlus.Store.MemoryDb.put_access(%UserAccess{token: token, access_id: access_id})

        # Save in the cookie
        conn
        |> CsrfPlus.put_session_token(token)
        |> put_session(:access_id, access_id)
        |> assign(:csrf_token, signed_token)

      _access_id ->
        Logger.info("Using existing session id")
        Logger.info("Using given signed token through request header")

        signed_token =
          conn
          |> get_req_header("x-csrf-token")
          |> List.first()

        conn
        |> assign(:csrf_token, signed_token)
    end
  end

  defp put_header_token(conn) do
    case Map.get(conn.assigns, :csrf_token) do
      nil ->
        halt(conn)

      signed_token ->
        Logger.info("csrf token at assigns: #{inspect(signed_token)}")
        # And send in the header
        conn
        |> put_resp_header("x-csrf-token", signed_token)
    end
  end
end
