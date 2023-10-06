defmodule RecaptchaWeb.FormController do
  alias RecaptchaWeb.TurnstileValidator
  alias Recaptcha.Validator
  use RecaptchaWeb, :controller

  require Logger

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
end
