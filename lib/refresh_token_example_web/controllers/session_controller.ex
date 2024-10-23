defmodule RefreshTokenExampleWeb.SessionController do
  use RefreshTokenExampleWeb, :controller
  alias RefreshTokenExample.Accounts
  alias RefreshTokenExample.Guardian
  import Ecto.Query

  def create(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        case Guardian.create_tokens(user) do
          {:ok, %{access_token: access_token, refresh_token: refresh_token}} ->
            conn
            |> put_status(:ok)
            |> json(%{
              access_token: access_token,
              refresh_token: refresh_token
            })
          {:error, reason} ->
            conn
            |> put_status(:unauthorized)
            |> json(%{error: "Failed to generate tokens: #{reason}"})
        end
      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid email or password"})
    end
  end

  def refresh(conn, %{"refresh_token" => refresh_token}) do
    case Guardian.exchange_refresh_token(refresh_token) do
      {:ok, %{access_token: access_token}} ->
        conn
        |> put_status(:ok)
        |> json(%{access_token: access_token})
      {:error, _reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "invalid_refresh_token"})
    end
  end

  @spec delete_all(any(), any()) :: none()
  def delete_all(conn, _params) do
    claims = Guardian.Plug.current_claims(conn)

    if claims do
      RefreshTokenExample.Repo.all(
        from(t in RefreshTokenExample.Token, where: fragment("claims ->> 'sub' = ?", ^claims["sub"]))
      )
      |> Enum.each(&Guardian.revoke(&1.jwt))

      conn
      |> put_status(:ok)
      |> json(%{message: "Logged out from all devices"})
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "invalid_token"})
    end
  end
end
