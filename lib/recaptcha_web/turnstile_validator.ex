defmodule RecaptchaWeb.TurnstileValidator do
  alias RecaptchaWeb.HttpClient

  require Logger

  def validate(token) do
    Application.get_env(:recaptcha, :dotenv)
    |> validate_with_env(token)
  end

  defp validate_with_env(nil, _token) do
    Logger.info("TurnstileValidator Error. Dotenv is not set.")
    {:error, %{error: "internal server error"}}
  end

  defp validate_with_env(
         %{"CAPTCHA_SECRET" => secret, "CAPTCHA_VALIDATION_URL" => url},
         token
       )
       when is_binary(url) do
    headers = [
      {"Content-Type", "application/json; charset=UTF-8"}
    ]

    body =
      Jason.encode!(%{
        secret: secret,
        response: token
      })

    case HttpClient.request(:post, url, headers, body) do
      {:ok, %{body: resp_body, status: resp_status}} ->
        resp_body = Jason.decode!(resp_body)

        Logger.debug(
          "TurnstileValidator Response: #{inspect(resp_body)}. Status: #{inspect(resp_status)}"
        )

        validate_response(resp_status, resp_body)

      error ->
        Logger.info("TurnstileValidator Error: #{inspect(error)}")
        {:error, %{error: "internal server error"}}
    end
  end

  defp validate_response(200, %{"success" => true, "action" => action, "hostname" => hostname}) do
    {:ok, %{action: action, hostname: hostname}}
  end

  defp validate_response(200, %{"success" => false, "error-codes" => codes}) do
    Logger.info("TurnstileValidator Error. Codes: #{inspect(codes)}")
    {:error, %{error: codes}}
  end

  defp validate_response(status, _body) do
    Logger.info("TurnstileValidator Error. Response status: #{status}")
    {:error, %{error: "internal server error"}}
  end
end
