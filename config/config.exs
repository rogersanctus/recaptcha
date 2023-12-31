# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :recaptcha,
  ecto_repos: [Recaptcha.Repo]

# Configures the endpoint
config :recaptcha, RecaptchaWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [json: RecaptchaWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Recaptcha.PubSub,
  live_view: [signing_salt: "FuaTdXGM"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :recaptcha, Recaptcha.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :recaptcha, :env_mode, config_env()

# Config CsrfPlus
config :csrf_plus, CsrfPlus, store: CsrfPlus.Store.MemoryDb

# Config the function to be used for tokens generation
config :csrf_plus, CsrfPlus.Token, token_generation_fn: &RecaptchaWeb.Csrf.generate_token/0

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
