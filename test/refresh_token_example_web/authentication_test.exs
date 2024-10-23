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
      assert json_response(conn, 401)["error"] == "invalid_refresh_token"
    end

    test "refresh token fails with access token", %{conn: conn} do
      user_params = %{email: "test@example.com", password: "password123"}
      {:ok, user} = Accounts.create_user(user_params)
      {:ok, %{access_token: access_token}} = Guardian.create_tokens(user)

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

    test "accessing protected resource fails with expired access token", %{conn: _conn} do
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

    test "refresh token can be used multiple times", %{conn: _conn} do
      user_params = %{email: "test@example.com", password: "password123"}
      {:ok, user} = Accounts.create_user(user_params)
      {:ok, %{refresh_token: refresh_token}} = Guardian.create_tokens(user)

      for _i <- 1..3 do
        conn = post(build_conn(), ~p"/api/sessions/refresh", refresh_token: refresh_token)
        assert %{"access_token" => new_access_token} = json_response(conn, 200)

        conn =
          build_conn()
          |> put_req_header("accept", "application/json")
          |> put_req_header("authorization", "Bearer #{new_access_token}")
          |> get(~p"/api/protected_resources")

        assert json_response(conn, 200)["message"] == "This is a protected resource"
      end
    end
  end

  describe "token revocation" do
    setup %{conn: conn} do
      user_params = %{email: "test@example.com", password: "password123"}
      {:ok, user} = Accounts.create_user(user_params)
      {:ok, %{access_token: access_token, refresh_token: refresh_token}} = Guardian.create_tokens(user)

      {:ok, %{
        conn: conn,
        user: user,
        access_token: access_token,
        refresh_token: refresh_token
      }}
    end

    test "successfully revokes all tokens", %{conn: conn, user: user, access_token: access_token} do
      # Create another token pair for the same user
      {:ok, %{access_token: second_access_token}} = Guardian.create_tokens(user)

      # Revoke all tokens
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{access_token}")
        |> delete(~p"/api/sessions/logout_all")

      assert json_response(conn, 200)["message"] == "Logged out from all devices"

      # Verify first access token doesn't work
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{access_token}")
        |> get(~p"/api/protected_resources")

      assert json_response(conn, 401)["error"] == "invalid_token"

      # Verify second access token doesn't work
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{second_access_token}")
        |> get(~p"/api/protected_resources")

      assert json_response(conn, 401)["error"] == "invalid_token"
    end

    test "new tokens work after revoking all tokens", %{conn: conn, user: user, access_token: access_token} do
      # Revoke all tokens
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{access_token}")
        |> delete(~p"/api/sessions/logout_all")

      assert json_response(conn, 200)["message"] == "Logged out from all devices"

      # Create new tokens
      {:ok, %{access_token: new_access_token}} = Guardian.create_tokens(user)

      # Verify new token works
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{new_access_token}")
        |> get(~p"/api/protected_resources")

      assert json_response(conn, 200)["message"] == "This is a protected resource"
    end

    test "refresh token stops working after token revocation", %{
      conn: conn,
      access_token: access_token,
      refresh_token: refresh_token
    } do
      # Revoke all tokens
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{access_token}")
        |> delete(~p"/api/sessions/logout_all")

      assert json_response(conn, 200)["message"] == "Logged out from all devices"

      # Try to use the refresh token
      conn = post(build_conn(), ~p"/api/sessions/refresh", refresh_token: refresh_token)
      assert json_response(conn, 401)["error"] == "invalid_refresh_token"
    end
  end
end
