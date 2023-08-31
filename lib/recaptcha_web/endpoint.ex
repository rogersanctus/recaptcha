defmodule RecaptchaWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :recaptcha

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_recaptcha_key",
    signing_salt: "5GiznhOp",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  plug Corsica,
    # Uses Recaptcha.Helper.check_cors_origin?/2 to check the origin against the allowed origins
    origins: [{Recaptcha.Helper, :check_cors_origin?, []}],
    expose_headers: ["x-csrf-token"],
    allow_credentials: true,
    allow_headers: ["content-type", "x-csrf-token", "x-captcha-token"],
    allow_methods: :all

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :recaptcha,
    gzip: false,
    only: RecaptchaWeb.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :recaptcha
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session, @session_options
  plug RecaptchaWeb.Router
end
