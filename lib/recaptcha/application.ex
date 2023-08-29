defmodule Recaptcha.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Creating new ets table and initializing tokens")
    :ets.new(:recaptcha_token_table, [:set, :public, :named_table])
    :ets.insert(:recaptcha_token_table, {:tokens, []})

    children = [
      # Start the Telemetry supervisor
      RecaptchaWeb.Telemetry,
      # Start the Ecto repository
      Recaptcha.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Recaptcha.PubSub},
      # Start Finch
      {Finch, name: Recaptcha.Finch},
      # Start the Endpoint (http/https)
      RecaptchaWeb.Endpoint
      # Start a worker by calling: Recaptcha.Worker.start_link(arg)
      # {Recaptcha.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Recaptcha.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RecaptchaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
