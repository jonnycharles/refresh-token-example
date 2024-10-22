defmodule RefreshTokenExample.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `RefreshTokenExample.Accounts` context.
  """


  @doc """
  Generate a unique user email.
  """
  def unique_user_email, do: "user-#{System.unique_integer([:positive])}@example.com"

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: unique_user_email(),
        password: "password123"
      })
      |> RefreshTokenExample.Accounts.create_user()

    user
  end
end
