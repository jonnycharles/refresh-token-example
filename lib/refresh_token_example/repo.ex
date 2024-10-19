defmodule RefreshTokenExample.Repo do
  use Ecto.Repo,
    otp_app: :refresh_token_example,
    adapter: Ecto.Adapters.Postgres
end
