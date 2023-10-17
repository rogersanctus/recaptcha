defmodule RecaptchaWeb.Router do
  alias CsrfPlus.UserAccess
  use RecaptchaWeb, :router

  # You can define another pipeline that doesn't use the CSRF plug
  # for endpoints that doesn't need such a protection.
  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session

    plug CsrfPlus,
      csrf_key: RecaptchaWeb.Csrf.csrf_key(),
      error_mapper: RecaptchaWeb.Csrf

    plug :put_csrf_token
    plug :put_secure_browser_headers
  end

  scope "/api", RecaptchaWeb do
    pipe_through :api

    post "/form", FormController, :post
    get "/form", FormController, :get
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:recaptcha, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: RecaptchaWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  # A local plug to just send the tokens over the connection response.
  defp put_csrf_token(conn, _opts) do
    access_id = get_session(conn, :access_id)
    access = access_id && CsrfPlus.Store.MemoryDb.get_access(access_id)

    token_tuple = CsrfPlus.get_token_tuple(conn)

    # Check if access is stored
    with %UserAccess{} <- access, {_token, signed_token} <- token_tuple do
      # In this case, send only the x-csrf-token header
      CsrfPlus.put_header_token(conn, signed_token)
    else
      _ ->
        # Otherwise, all tokens must be updated
        conn
        |> CsrfPlus.put_token(token_tuple: token_tuple)
    end
  end
end
