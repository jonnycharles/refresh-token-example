defmodule RefreshTokenExampleWeb.SessionController do
  use RefreshTokenExampleWeb, :controller
  alias RefreshTokenExample.Accounts
  alias RefreshTokenExample.Guardian

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
      {:error, :invalid_refresh_token} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "invalid_refresh_token"})
      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Failed to refresh token: #{reason}"})
    end
  end
end
