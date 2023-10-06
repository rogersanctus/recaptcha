defmodule Recaptcha.ErrorHandler do
  defmacro __using__(_opts) do
    quote do
      @before_compile Recaptcha.ErrorHandler

      @behaviour Plug.ErrorHandler
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defoverridable call: 2

      def call(conn, opts) do
        try do
          super(conn, opts)
        rescue
          e in Plug.Conn.WrapperError ->
            %{conn: conn, kind: kind, reason: reason, stack: stack} = e
            Recaptcha.ErrorHandler.__catch__(conn, kind, e, stack, &handle_errors/2)
        catch
          kind, reason ->
            Recaptcha.ErrorHandler.__catch__(
              conn,
              kind,
              reason,
              __STACKTRACE__,
              &handle_errors/2
            )
        end
      end
    end
  end

  def __catch__(conn, kind, reason, stack, handle_errors) do
    normalized_reason = Exception.normalize(kind, reason, stack)

    conn
    |> handle_errors.(%{kind: kind, reason: normalized_reason, stack: stack})
  end
end
