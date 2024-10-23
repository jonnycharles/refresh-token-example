defmodule RefreshTokenExampleWeb.ProtectedResourceController do
  use RefreshTokenExampleWeb, :controller
  alias RefreshTokenExample.Guardian

  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    conn
    |> put_status(:ok)
    |> json(%{
      message: "This is a protected resource",
      user_id: user.id
    })
  end
end
