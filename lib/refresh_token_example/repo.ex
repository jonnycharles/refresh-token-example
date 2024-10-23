defmodule RefreshTokenExample.Repo do
  use Ecto.Repo,
    otp_app: :refresh_token_example,
    adapter: Ecto.Adapters.Postgres

  import Ecto.Query, warn: false

  @doc """
  Reloads a struct from the database.
  Returns nil if the record no longer exists or if nil is passed.
  """
  def reload_record(nil), do: nil
  def reload_record(%{__struct__: schema, id: id}) do
    __MODULE__.get(schema, id)
  end
end
