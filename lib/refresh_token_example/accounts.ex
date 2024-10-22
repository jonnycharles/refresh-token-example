defmodule RefreshTokenExample.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias RefreshTokenExample.Repo
  alias RefreshTokenExample.Accounts.User
  alias Bcrypt

  def authenticate_user(email, password) do
    with %User{} = user <- Repo.get_by(User, email: email),
         true <- Bcrypt.verify_pass(password, user.password_hash) do
      {:ok, clear_password(user)}
    else
      nil -> {:error, :invalid_credentials}
      false -> {:error, :invalid_credentials}
    end
  end

  @doc """
  Returns the list of users.
  """
  def list_users do
    User
    |> Repo.all()
    |> Enum.map(&clear_password/1)
  end

  @doc """
  Gets a single user.
  """
  def get_user!(id) do
    User
    |> Repo.get!(id)
    |> clear_password()
  end

  @doc """
  Creates a user.
  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, user} -> {:ok, clear_password(user)}
      error -> error
    end
  end

  @doc """
  Updates a user.
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, user} -> {:ok, clear_password(user)}
      error -> error
    end
  end

  @doc """
  Deletes a user.
  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  # Private function to clear the password field
  defp clear_password(%User{} = user) do
    %{user | password: nil}
  end
end
