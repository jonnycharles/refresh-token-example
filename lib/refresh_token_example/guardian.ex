defmodule RefreshTokenExample.Guardian do
  use Guardian, otp_app: :refresh_token_example

  alias RefreshTokenExample.Accounts

  # Guardian.DB callbacks
  def after_encode_and_sign(resource, claims, token, _options) do
    with {:ok, _} <- Guardian.DB.after_encode_and_sign(resource, claims["typ"], claims, token) do
      {:ok, token}
    end
  end

  def on_verify(claims, token, _options) do
    with {:ok, _} <- Guardian.DB.on_verify(claims, token) do
      {:ok, claims}
    end
  end

  def on_refresh({old_token, old_claims}, {new_token, new_claims}, _options) do
    with {:ok, _, _} <- Guardian.DB.on_refresh({old_token, old_claims}, {new_token, new_claims}) do
      {:ok, {old_token, old_claims}, {new_token, new_claims}}
    end
  end

  def on_revoke(claims, token, _options) do
    with {:ok, _} <- Guardian.DB.on_revoke(claims, token) do
      {:ok, claims}
    end
  end

  @spec subject_for_token(any(), any()) :: {:ok, binary()}
  def subject_for_token(user, _claims) do
    {:ok, to_string(user.id)}
  end

  def resource_from_claims(%{"sub" => id}) do
    case Accounts.get_user!(id) do
      nil -> {:error, :resource_not_found}
      user -> {:ok, user}
    end
  end

  def create_tokens(user) do
    current_time = DateTime.utc_now()

    base_claims = %{
      "iat" => DateTime.to_unix(current_time),
      "created_at" => DateTime.to_string(current_time)
    }

    with {:ok, access_token, access_claims} <-
           encode_and_sign(user, base_claims, token_type: "access", ttl: {15, :minute}),
         {:ok, refresh_token, refresh_claims} <-
           encode_and_sign(user, base_claims, token_type: "refresh", ttl: {7, :day}) do


      {
        :ok,
        %{
          access_token: access_token,
          refresh_token: refresh_token,
          access_claims: access_claims,
          refresh_claims: refresh_claims
        }
      }
    end
  end

  def exchange_refresh_token(refresh_token) do
    with {:ok, claims} <- decode_and_verify(refresh_token),
         true <- validate_token_type(claims),
         {:ok, user} <- resource_from_claims(claims) do
      create_new_access_token(user)
    else
      {:error, _reason} = _error ->
        {:error, :invalid_refresh_token}
      false ->
        {:error, :invalid_refresh_token}
    end
  end

  defp create_new_access_token(user) do
    current_time = DateTime.utc_now()
    issued_at = DateTime.to_unix(current_time)

    base_claims = %{
      "iat" => issued_at,
      "created_at" => DateTime.to_string(current_time)
    }

    case encode_and_sign(user, base_claims, token_type: "access", ttl: {15, :minute}) do
      {:ok, access_token, claims} ->
        {:ok, %{access_token: access_token, access_claims: claims}}
      _error ->
        {:error, :invalid_refresh_token}
    end
  end

  def build_claims(claims, _resource, opts) do
    built_claims = claims |> Map.put("typ", Keyword.get(opts, :token_type, "access"))
    {:ok, built_claims}
  end

  defp validate_token_type(%{"typ" => "refresh"}), do: true
  defp validate_token_type(_), do: false
end
