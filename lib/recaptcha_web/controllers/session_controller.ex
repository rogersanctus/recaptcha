defmodule RecaptchaWeb.SessionController do
  alias Ecto.UUID
  use RecaptchaWeb, :controller

  require Logger

  def sync(conn, _params) do
    show_ip_address(conn)

    conn
    |> put_cookie_token()
    |> put_header_token()
    |> put_status(:no_content)
    |> put_secure_browser_headers()
    |> text("")
  end

  defp show_ip_address(conn) do
    Logger.info("IP address: #{inspect(conn.remote_ip)}")

    Plug.Conn.get_req_header(conn, "x-real-ip")
    |> IO.inspect(label: "x-real-ip")

    Plug.Conn.get_req_header(conn, "x-forwarded-for")
    |> IO.inspect(label: "x-forwarded-for")
  end

  defp put_cookie_token(conn) do
    case Plug.Conn.get_session(conn, :recaptcha_session_id) do
      nil ->
        Logger.info("Creating new session id")

        session_id =
          UUID.generate()
          |> Base.encode64()

        ets_save_session_id(session_id)

        conn
        # Save in the cookie
        |> Plug.Conn.put_session(:recaptcha_session_id, session_id)

      _ ->
        Logger.info("Using existing session id")
        conn
    end
  end

  defp put_header_token(conn) do
    case Plug.Conn.get_session(conn, :recaptcha_session_id) do
      nil ->
        halt(conn)

      session_id ->
        # And send in the header
        conn
        |> Plug.Conn.put_resp_header("x-token-recaptcha", session_id)
    end
  end

  defp ets_save_session_id(session_id) do
    Logger.info("Adding token to the ets table")
    tokens = :ets.lookup_element(:recaptcha_token_table, :tokens, 2)
    :ets.insert(:recaptcha_token_table, {:tokens, [session_id | tokens]})
  end
end
