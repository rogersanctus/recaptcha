defmodule RecaptchaWeb.FormController do
  alias RecaptchaWeb.TurnstileValidator
  alias Recaptcha.Validator
  alias CsrfPlus.UserAccess

  use RecaptchaWeb, :controller

  require Logger

  def get(conn, _params) do
    conn
    |> put_cookie_token()
    |> put_header_token()
    |> put_secure_browser_headers()
    |> send_resp(:no_content, "")
  end

  def post(conn, %{"email" => email, "captcha_token" => captcha_token}) do
    validator =
      %Validator{stop_on_error: true}
      |> Validator.validate(:email, fn -> validate_email(email) end)
      |> Validator.validate(:captcha, fn -> validate_captcha(captcha_token) end)

    if not Validator.has_errors?(validator) do
      conn
      |> put_status(:ok)
      |> render(:post, email: email)
    else
      halt_conn(conn, validator.errors)
    end
  end

  def post(conn, _params) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: %{general: "Invalid parameters"}})
  end

  def validate_email(nil) do
    "is required"
  end

  def validate_email(email) when is_binary(email) do
    cond do
      String.trim(email) |> String.length() == 0 ->
        "is required"

      not String.match?(email, ~r/.+@.+/) ->
        "is invalid"

      true ->
        true
    end
  end

  defp validate_captcha(token) do
    case TurnstileValidator.validate(token) do
      {:ok, _} ->
        true

      {:error, error} ->
        Jason.encode!(error)
    end
  end

  defp halt_conn(conn, errors) do
    conn
    |> put_status(:unauthorized)
    |> json(%{errors: errors})
    |> halt()
  end

  defp put_cookie_token(conn) do
    case get_session(conn, :access_id) do
      nil ->
        put_new_cookie_token(conn)

      access_id ->
        case CsrfPlus.Store.MemoryDb.get_access(access_id) do
          nil ->
            put_new_cookie_token(conn)

          _ ->
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
  end

  defp put_new_cookie_token(conn) do
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
