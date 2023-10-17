defmodule RecaptchaWeb.Csrf do
  @behaviour CsrfPlus.ErrorMapper

  @csrf_key "_csrf_token"

  def csrf_key, do: @csrf_key

  def generate_token() do
    :crypto.strong_rand_bytes(32)
    |> Base.url_encode64(padding: false)
  end

  def map(exception) do
    {
      :unauthorized,
      %{
        errors: [
          %{
            key: "csrf",
            message: exception.message
          }
        ]
      }
    }
  end
end
