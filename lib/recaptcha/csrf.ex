defmodule Recaptcha.Csrf do
  @moduledoc false
  alias Recaptcha.Csrf.UserAccessInfo
  require Logger

  @behaviour Plug

  @default_csrf_key "_csrf_token_"
  @non_csrf_request_methods ["GET", "HEAD", "OPTIONS"]

  import Plug.Conn

  def init(opts \\ []) do
    csrf_key = Keyword.get(opts, :csrf_key, @default_csrf_key)
    allowed_origins = Keyword.get(opts, :allowed_origins, [])

    %{
      csrf_key: csrf_key,
      allowed_origins: allowed_origins
    }
  end

  def call(%Plug.Conn{} = conn, %{allowed_methods: allowed_methods} = opts) do
    if conn.method in allowed_methods do
      conn
    else
      {conn, opts} = prepare_for_checks(conn, opts)

      try_do_checks(conn, opts)
    end
  end

  defp prepare_for_checks(%Plug.Conn{host: host} = conn, %{allowed_origins: []} = opts)
       when is_binary(host) do
    {conn, Map.put(opts, :allowed_origins, [host])}
  end

  defp prepare_for_checks(
         %Plug.Conn{host: host} = conn,
         %{allowed_origins: allowed_origins} = opts
       ) do
    origins =
      if conn.host in allowed_origins do
        allowed_origins
      else
        [host | allowed_origins]
      end

    {conn, Map.put(opts, :allowed_origins, origins)}
  end

  defp prepare_for_checks(conn, opts) do
    conn =
      conn
      |> send_resp(500, "")
      |> halt()

    {conn, opts}
  end

  defp try_do_checks(%Plug.Conn{halted: true} = conn, _opts) do
    conn
  end

  defp try_do_checks(%Plug.Conn{} = conn, opts) do
    check_origins(conn, opts)
    |> try_check_token(opts)
  end

  defp try_check_token(%Plug.Conn{halted: true} = conn, _opts) do
    conn
  end

  defp try_check_token(%Plug.Conn{} = conn, opts) do
    check_token(conn, opts)
  end

  defp check_token(%Plug.Conn{} = conn, opts) do
    store = Application.get_env(opts.otp_app, :store, Recaptcha.Csrf.Store.BdStore)

    user_info = %UserAccessInfo{
      ip: get_conn_ip(conn),
      user_agent: get_conn_user_agent(conn)
    }

    header_token = get_req_header(conn, "x-csrf-token")

    store_token = store.get_token(user_info)

    if header_token == store_token do
      conn
    else
      Logger.debug("Token mismatch: #{inspect(header_token)} != #{inspect(store_token)}")

      conn
      |> send_resp(:unauthorized, Jason.encode!(%{error: "Invalid token"}))
    end
  end

  defp get_conn_ip(%Plug.Conn{remote_ip: remote_ip, req_headers: req_headers}) do
    [x_real_ip | _] = List.keyfind(req_headers, "x-real-ip", 0)
    [x_forwarded_for | _] = List.keyfind(req_headers, "x-forwarded-for", 0)

    case {remote_ip, x_real_ip, x_forwarded_for} do
      {nil, nil, nil} ->
        nil

      {nil, nil, x_forwarded_for} ->
        x_forwarded_for

      {nil, x_real_ip, nil} ->
        x_real_ip

      {remote_ip, nil, nil} ->
        remote_ip
    end
  end

  defp get_conn_user_agent(%Plug.Conn{} = conn) do
    conn
    |> get_req_header("user-agent")
    |> hd
  end

  defp check_origins(
         %Plug.Conn{req_headers: headers} = conn,
         %{allowed_origins: allowed_origins}
       )
       when is_list(allowed_origins) do
    case List.keyfind(headers, "origin", 0) do
      nil ->
        conn
        |> send_resp(:unauthorized, Jason.encode!(%{error: "Missing Origin header"}))
        |> halt()

      origin ->
        allowed_origins
        |> Enum.any?(fn allowed_origin -> check_origin(origin, allowed_origin) end)
        |> check_origins_result(conn)
    end
  end

  defp check_origins_result(true, conn) do
    conn
  end

  defp check_origins_result(false, conn) do
    conn
    |> send_resp(:unauthorized, Jason.encode!(%{error: "Origin not allowed"}))
    |> halt()
  end

  defp check_origin(origin, allowed_origin) when is_binary(allowed_origin) do
    origin == allowed_origin
  end

  defp check_origin(origin, %Regex{} = allowed_origin) do
    Regex.match?(allowed_origin, origin)
  end

  defp check_origin(origin, allowed_origin) when is_function(allowed_origin) do
    allowed_origin.(origin)
  end

  defp check_origin(_origin, _allowed_origin) do
    false
  end
end
