defmodule RefreshTokenExampleWebWeb.AuthenticationTest do
  use RefreshTokenExampleWeb.ConnCase
  alias RefreshTokenExample.Accounts
  alias RefreshTokenExample.Guardian

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "Authentication" do
    test "full authentication flow", %{conn: conn} do
      # Debug: Print Guardian secret key

      user_params = %{email: "test@example.com", password: "password123"}

      # 1. Test user creation
      conn = post(conn, ~p"/api/users", user: user_params)
      assert %{"data" => %{"id" => user_id, "email" => "test@example.com"}} = json_response(conn, 201)

      # 2. Test login
      conn = post(conn, ~p"/api/sessions", email: "test@example.com", password: "password123")
      response = json_response(conn, 200)

      assert %{"token" => token} = response

      # If there's an error, print it for debugging
      if Map.has_key?(response, "error") do
        IO.puts("Login Error: #{response["error"]}")
      end

      # 3. Verify the token
      case Guardian.decode_and_verify(token) do
        {:ok, claims} ->
          assert claims["sub"] == user_id
        {:error, reason} ->
          flunk("Failed to decode and verify token: #{inspect(reason)}")
      end

      # 4. Test accessing a protected resource
      conn =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/protected_resources")

      assert json_response(conn, 200)["message"] == "This is a protected resource"
      assert json_response(conn, 200)["user_id"] == user_id
    end

    test "login fails with invalid credentials", %{conn: conn} do
      conn = post(conn, ~p"/api/sessions", email: "wrong@example.com", password: "wrongpassword")
      assert json_response(conn, 401)["error"] == "Invalid email or password"
    end

    test "accessing protected resource fails without token", %{conn: conn} do
      conn = get(conn, ~p"/api/protected_resources")
      assert json_response(conn, 401)["error"] == "unauthenticated"
    end
  end
end
