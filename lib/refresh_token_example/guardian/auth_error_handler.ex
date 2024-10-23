defmodule RefreshTokenExampleWeb.Guardian.AuthErrorHandler do
  use RefreshTokenExampleWeb, :controller

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, _reason}, _opts) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: to_string(type)})
  end
end
