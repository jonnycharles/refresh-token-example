defmodule RefreshTokenExample.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Bcrypt

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string
    field :password_hash, :string, redact: true
    field :password, :string, virtual: true, redact: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unique_constraint(:email)
    |> validate_length(:password, min: 6)
    |> hash_password()
  end

  defp hash_password(changeset) do
    case get_change(changeset, :password) do
      nil ->
        changeset

      password ->
        put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
    end
  end
end
