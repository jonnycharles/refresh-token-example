defmodule RefreshTokenExample.AccountsTest do
  use RefreshTokenExample.DataCase

  alias RefreshTokenExample.Accounts

  describe "users" do
    alias RefreshTokenExample.Accounts.User

    import RefreshTokenExample.AccountsFixtures

    @invalid_attrs %{password: nil, email: nil}

    test "list_users/0 returns all users" do
      user = user_fixture()
      [listed_user] = Accounts.list_users()
      assert listed_user.id == user.id
      assert listed_user.email == user.email
      assert listed_user.password_hash == user.password_hash
      assert listed_user.password == nil
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      fetched_user = Accounts.get_user!(user.id)
      assert fetched_user.id == user.id
      assert fetched_user.email == user.email
      assert fetched_user.password_hash == user.password_hash
      assert fetched_user.password == nil
    end

    test "create_user/1 with valid data creates a user" do
      valid_attrs = %{email: "test@example.com", password: "password123"}

      assert {:ok, %User{} = user} = Accounts.create_user(valid_attrs)
      assert user.email == "test@example.com"
      assert user.password == nil
      assert Bcrypt.verify_pass("password123", user.password_hash)
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      update_attrs = %{email: "updated@example.com", password: "newpassword123"}

      assert {:ok, %User{} = updated_user} = Accounts.update_user(user, update_attrs)
      assert updated_user.email == "updated@example.com"
      assert updated_user.password == nil
      assert Bcrypt.verify_pass("newpassword123", updated_user.password_hash)
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      fetched_user = Accounts.get_user!(user.id)
      assert user.email == fetched_user.email
      assert user.password_hash == fetched_user.password_hash
      assert fetched_user.password == nil
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end
end
