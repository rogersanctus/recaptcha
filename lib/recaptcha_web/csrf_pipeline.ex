defmodule RecaptchaWeb.CsrfPipeline do
  use Plug.Builder
  use Recaptcha.ErrorHandler
  import Phoenix.Controller

  plug CsrfPlus, csrf_key: RecaptchaWeb.SessionController.csrf_key()

  def handle_errors(conn, %{kind: :error, reason: exception, stack: stack}) do
    if CsrfPlus.Exception.csrf_plus_exception?(exception) do
      conn
      |> put_status(:unauthorized)
      |> json(%{
        errors: [%{key: "csrf", message: exception.message}]
      })
      |> halt()
    else
      internal_error(conn, exception, stack)
    end
  end

  def handle_errors(conn, %{kind: _kind, reason: reason, stack: stack}) do
    internal_error(conn, reason, stack)
  end

  defp internal_error(conn, reason, stack) do
    conn
    |> put_status(500)
    |> json(%{
      errors: [
        %{
          key: "general",
          message: "Internal Server Error",
          reason: "#{inspect(reason)}",
          stack: "#{inspect(stack)}"
        }
      ]
    })
    |> halt()
  end
end
