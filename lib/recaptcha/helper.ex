defmodule Recaptcha.Helper do
  require Logger

  def get_header(%Plug.Conn{req_headers: headers} = _conn, key) do
    case List.keyfind(headers, key, 0, nil) do
      nil -> nil
      {_key, value} -> value
    end
  end

  def load_dotenv() do
    # Loads dotenv
    env_mode = Application.get_env(:recaptcha, :env_mode)
    envs = [".env"]

    envs =
      if is_nil(env_mode) do
        Logger.warning(":env_mode is not set in the application config.")
        envs
      else
        Logger.info(":env_mode = #{env_mode}")
        envs ++ [".env.#{env_mode}"]
      end

    dotenv = Dotenvy.source!(envs)
    Application.put_env(:recaptcha, :dotenv, dotenv)
  end

  @spec get_allowed_origins() :: [Regex.t()]
  def get_allowed_origins() do
    Logger.info("Trying to get allowed origins")

    case Application.get_env(:recaptcha, :dotenv) do
      nil ->
        Logger.error(":dotenv is not set in the application config")
        []

      dotenv ->
        allowed_origins = Map.get(dotenv, "ALLOWED_ORIGINS", "[]")

        case Jason.decode(allowed_origins) do
          {:ok, allowed_origins} ->
            Enum.into(allowed_origins, [], fn origin -> Regex.compile!(origin) end)

          _ ->
            Logger.error("Error decoding ALLOWED_ORIGINS")
            []
        end
    end
  end

  @spec check_cors_origin?(Plug.Conn.t(), String.t()) :: boolean()
  def check_cors_origin?(%Plug.Conn{} = _conn, actual_origin) do
    get_allowed_origins()
    |> Enum.any?(fn allowed_origin -> Regex.match?(allowed_origin, actual_origin) end)
  end
end
