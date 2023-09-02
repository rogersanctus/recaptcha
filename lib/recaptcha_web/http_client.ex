defmodule RecaptchaWeb.HttpClient do
  @moduledoc """
  HTTP Client
  """

  defp client_name() do
    Recaptcha.Finch
  end

  @spec request(atom(), Finch.Reque.url(), Finch.Request.headers(), Finch.Request.body()) ::
          {:ok, Finch.Response.t()} | {:error, Exception.t()}
  def request(method, url, headers \\ [], body \\ nil) do
    Finch.build(method, url, headers, body)
    |> Finch.request(client_name())
  end
end
