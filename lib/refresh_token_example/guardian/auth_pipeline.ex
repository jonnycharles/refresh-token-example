defmodule RefreshTokenExampleWeb.Guardian.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :refresh_token_example,
    module: RefreshTokenExample.Guardian,
    error_handler: RefreshTokenExampleWeb.Guardian.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, realm: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
