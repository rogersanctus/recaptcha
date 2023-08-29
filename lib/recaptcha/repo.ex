defmodule Recaptcha.Repo do
  use Ecto.Repo,
    otp_app: :recaptcha,
    adapter: Ecto.Adapters.Postgres
end
