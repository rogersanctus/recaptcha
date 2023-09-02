defmodule RecaptchaWeb.FormController do
  alias RecaptchaWeb.TurnstileValidator
  alias Recaptcha.Validator
  use RecaptchaWeb, :controller

  require Logger

  def post(conn, %{"email" => email, "captcha_token" => captcha_token}) do
    header_token = Recaptcha.Helper.get_header(conn, "x-csrf-token")
    cookie_token = Plug.Conn.get_session(conn, :recaptcha_session_id)

    validator =
      %Validator{stop_on_error: true}
      |> Validator.validate(:email, fn -> validate_email(email) end)
      |> Validator.validate(:csrf, fn -> validate_csrf(cookie_token, header_token) end)
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

  defp validate_csrf(cookie_token, header_token) do
    cond do
      is_nil(header_token) || is_nil(cookie_token) ->
        Logger.info("Token in the header or in the cookie is nil")
        "is required"

      header_token != cookie_token ->
        Logger.info("Token in the header don't match the one in the cookie")
        "is invalid"

      true ->
        ets_verify_token(header_token)
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

  defp ets_verify_token(token) do
    cond do
      :ets.whereis(:recaptcha_token_table) == :undefined ->
        "tokens list is not available"

      true ->
        tokens = :ets.lookup_element(:recaptcha_token_table, :tokens, 2)

        case Enum.find(tokens, fn ets_token -> ets_token == token end) do
          nil ->
            Logger.info("Token is not in the valid tokens table")
            "not signed"

          _ ->
            true
        end
    end
  end

  defp halt_conn(conn, errors) do
    conn
    |> put_status(:unauthorized)
    |> json(%{errors: errors})
    |> halt()
  end
end
