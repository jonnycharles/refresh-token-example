defmodule RefreshTokenExampleWeb.AuthenticationTest do
  use RefreshTokenExampleWeb.ConnCase
  alias RefreshTokenExample.Accounts
  alias RefreshTokenExample.Guardian

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "Authentication" do
    test "complete authentication flow with refresh token", %{conn: conn} do
      user_params = %{email: "test@example.com", password: "password123"}

      # 1. Create user
      conn = post(conn, ~p"/api/users", user: user_params)
      assert %{"data" => %{"id" => user_id, "email" => "test@example.com"}} = json_response(conn, 201)

      # 2. Login and get both tokens
      conn = post(conn, ~p"/api/sessions", email: "test@example.com", password: "password123")
      response = json_response(conn, 200)

      assert %{
               "access_token" => access_token,
               "refresh_token" => refresh_token
             } = response

      # If there's an error, print it for debugging
      if Map.has_key?(response, "error") do
        IO.puts("Login Error: #{response["error"]}")
      end

      # 3. Verify both tokens
      {:ok, access_claims} = Guardian.decode_and_verify(access_token)
      assert access_claims["sub"] == user_id
      assert access_claims["typ"] == "access"

      {:ok, refresh_claims} = Guardian.decode_and_verify(refresh_token)
      assert refresh_claims["sub"] == user_id
      assert refresh_claims["typ"] == "refresh"

      # 4. Access protected resource with access token
      conn =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer #{access_token}")
        |> get(~p"/api/protected_resources")

      assert json_response(conn, 200)["message"] == "This is a protected resource"
      assert json_response(conn, 200)["user_id"] == user_id

      # 5. Refresh access token
      conn = post(build_conn(), ~p"/api/sessions/refresh", refresh_token: refresh_token)
      refresh_response = json_response(conn, 200)
      assert %{"access_token" => new_access_token} = refresh_response

      # 6. Verify new access token
      {:ok, new_access_claims} = Guardian.decode_and_verify(new_access_token)
      assert new_access_claims["sub"] == user_id
      assert new_access_claims["typ"] == "access"

      # 7. Access protected resource with new access token
      conn =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer #{new_access_token}")
        |> get(~p"/api/protected_resources")

      assert json_response(conn, 200)["message"] == "This is a protected resource"
      assert json_response(conn, 200)["user_id"] == user_id
    end

    test "refresh token fails with invalid token", %{conn: conn} do
      conn = post(conn, ~p"/api/sessions/refresh", refresh_token: "invalid_token")
      assert json_response(conn, 401)["error"] == "Failed to refresh token: invalid_token"
    end

    test "refresh token fails with access token", %{conn: conn} do
      # First create a user and get tokens
      user_params = %{email: "test@example.com", password: "password123"}
      {:ok, user} = Accounts.create_user(user_params)
      {:ok, %{access_token: access_token}} = Guardian.create_tokens(user)

      # Try to use access token as refresh token
      conn = post(conn, ~p"/api/sessions/refresh", refresh_token: access_token)
      assert json_response(conn, 401)["error"] == "invalid_refresh_token"
    end

    test "login fails with invalid credentials", %{conn: conn} do
      conn = post(conn, ~p"/api/sessions", email: "wrong@example.com", password: "wrongpassword")
      assert json_response(conn, 401)["error"] == "Invalid email or password"
    end

    test "accessing protected resource fails without token", %{conn: conn} do
      conn = get(conn, ~p"/api/protected_resources")
      assert json_response(conn, 401)["error"] == "unauthenticated"
    end

    test "accessing protected resource fails with expired access token", %{conn: conn} do
      # Create a user and generate a token that expires immediately
      user_params = %{email: "test@example.com", password: "password123"}
      {:ok, user} = Accounts.create_user(user_params)
      {:ok, token, _claims} = Guardian.encode_and_sign(user, %{}, token_type: "access", ttl: {0, :second})

      # Wait a moment to ensure token expiration
      Process.sleep(1000)

      conn =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/protected_resources")

      assert json_response(conn, 401)["error"] == "invalid_token"
    end

    test "refresh token can be used multiple times", %{conn: conn} do
      # Create user and get tokens
      user_params = %{email: "test@example.com", password: "password123"}
      {:ok, user} = Accounts.create_user(user_params)
      {:ok, %{refresh_token: refresh_token}} = Guardian.create_tokens(user)

      # Use refresh token multiple times
      for _i <- 1..3 do
        conn = post(build_conn(), ~p"/api/sessions/refresh", refresh_token: refresh_token)
        assert %{"access_token" => new_access_token} = json_response(conn, 200)

        # Verify the new access token works
        conn =
          build_conn()
          |> put_req_header("accept", "application/json")
          |> put_req_header("authorization", "Bearer #{new_access_token}")
          |> get(~p"/api/protected_resources")

        assert json_response(conn, 200)["message"] == "This is a protected resource"
      end
    end
  end
end
