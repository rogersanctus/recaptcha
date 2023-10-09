defmodule RecaptchaWeb.Csrf do
  @behaviour CsrfPlus.ErrorMapper

  @csrf_key "_csrf_token"

  def csrf_key, do: @csrf_key

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
