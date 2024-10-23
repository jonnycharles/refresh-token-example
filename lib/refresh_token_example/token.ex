defmodule RefreshTokenExample.Token do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:jti, :string, []}
  @derive {Phoenix.Param, key: :jti}

  schema "guardian_tokens" do
    field(:aud, :string, primary_key: true)
    field(:typ, :string)
    field(:iss, :string)
    field(:sub, :string)
    field(:exp, :integer)
    field(:jwt, :string)
    field(:claims, :map)

    timestamps()
  end

  def changeset(token, attrs) do
    token
    |> cast(attrs, [:jti, :aud, :typ, :iss, :sub, :exp, :jwt, :claims])
    |> validate_required([:jti, :aud, :typ, :iss, :sub, :exp, :jwt, :claims])
    |> unique_constraint(:jti)
  end
end
