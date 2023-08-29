defmodule RecaptchaWeb.FormController do
  use RecaptchaWeb, :controller

  require Logger

  def post(conn, %{"email" => email}) do
    case validate_csrf(conn) do
      %Plug.Conn{halted: true} = conn ->
        conn

      conn ->
        conn
        |> put_status(:ok)
        |> render(:post, email: email)
    end
  end

  def post(conn, _params) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(RecaptchaWeb.ErrorJSON)
    |> render("error.json", %{error: "Invalid parameters"})
  end

  defp validate_csrf(conn) do
    header = Recaptcha.Helper.get_header(conn, "x-token-recaptcha")
    cookie = Plug.Conn.get_session(conn, :recaptcha_session_id)

    cond do
      is_nil(header) || is_nil(cookie) ->
        Logger.info("Token in the header or in the cookie is nil")
        halt_conn(conn)

      header != cookie ->
        Logger.info("Token in the header don't match the one in the cookie")
        halt_conn(conn)

      true ->
        ets_verify_token(conn, header)
    end
  end

  defp ets_verify_token(conn, token) do
    cond do
      :ets.whereis(:recaptcha_token_table) == :undefined ->
        halt_conn(conn)

      true ->
        tokens = :ets.lookup_element(:recaptcha_token_table, :tokens, 2)

        case Enum.find(tokens, fn ets_token -> ets_token == token end) do
          nil ->
            Logger.info("Token is not in the valid tokens table")
            halt_conn(conn)

          _ ->
            conn
        end
    end
  end

  defp halt_conn(conn) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: "Invalid CSRF token"})
    |> halt()
  end
end
