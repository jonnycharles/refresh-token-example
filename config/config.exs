# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :refresh_token_example,
  ecto_repos: [RefreshTokenExample.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

# Configures the endpoint
config :refresh_token_example, RefreshTokenExampleWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: RefreshTokenExampleWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: RefreshTokenExample.PubSub,
  live_view: [signing_salt: "kL349ZNp"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :refresh_token_example, RefreshTokenExample.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :refresh_token_example, RefreshTokenExample.Guardian,
  issuer: "refresh_token_example",
  secret_key: {System, :get_env, ["GUARDIAN_SECRET_KEY"]}

config :guardian, Guardian.DB,
  repo: RefreshTokenExample.Repo,
  schema_name: "guardian_tokens",
  sweep_interval: 60,  # in minutes
  token_types: ["access", "refresh"]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
