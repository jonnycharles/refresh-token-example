defmodule RefreshTokenExample.Guardian do
  use Guardian, otp_app: :refresh_token_example

  alias RefreshTokenExample.Accounts

  def subject_for_token(user, _claims) do
    {:ok, to_string(user.id)}
  end

  def resource_from_claims(%{"sub" => id}) do
    case Accounts.get_user!(id) do
      nil -> {:error, :resource_not_found}
      user -> {:ok, user}
    end
  end

   # Generate both access and refresh tokens
   def create_tokens(user) do
    with {:ok, access_token, access_claims} <-
           encode_and_sign(user, %{}, token_type: "access", ttl: {15, :minute}),
         {:ok, refresh_token, refresh_claims} <-
           encode_and_sign(user, %{}, token_type: "refresh", ttl: {7, :day}) do
      {
        :ok,
        %{
          access_token: access_token,
          refresh_token: refresh_token,
          access_claims: access_claims,
          refresh_claims: refresh_claims
        }
      }
    else
      error -> error
    end
  end

  # Exchange refresh token for new access token
  def exchange_refresh_token(refresh_token) do
    with {:ok, claims} <- decode_and_verify(refresh_token),
         :ok <- verify_token_type(claims),
         {:ok, user} <- resource_from_claims(claims),
         {:ok, access_token, access_claims} <-
           encode_and_sign(user, %{}, token_type: "access", ttl: {15, :minute}) do
      {:ok, %{access_token: access_token, access_claims: access_claims}}
    else
      {:error, :invalid_token_type} -> {:error, :invalid_refresh_token}
      error -> error
    end
  end

  # Add a private function to verify token type
  defp verify_token_type(%{"typ" => "refresh"}), do: :ok
  defp verify_token_type(_), do: {:error, :invalid_token_type}
end
