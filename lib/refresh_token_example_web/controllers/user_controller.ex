defmodule RefreshTokenExampleWeb.UserController do
  use RefreshTokenExampleWeb, :controller
  alias RefreshTokenExample.Accounts
  alias RefreshTokenExample.Accounts.User

  action_fallback RefreshTokenExampleWeb.FallbackController

  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params) do
      conn
      |> put_status(:created)
      |> json(%{data: %{id: user.id, email: user.email}})
    end
  end
end
