defmodule Core.Integrity do
  @moduledoc """
  Sign and verify various data that is passed through users
  """

  def sign(data) do
    secret = Application.get_env(:core, Core.Integrity)[:secret_key] |> Base.decode16!(case: :lower)

    :crypto.macN(:hmac, :sha256, secret, data, 16) |> Base.encode16(case: :lower)
  end

  def verify(data, tag) when is_binary(tag) do
    secret = Application.get_env(:core, Core.Integrity)[:secret_key] |> Base.decode16!(case: :lower)

    expected = :crypto.macN(:hmac, :sha256, secret, data, 16)

    case Base.decode16(tag, case: :lower) do
      {:ok, result} -> if expected == result, do: :ok, else: :error
      :error -> :error
    end
  end

  def verify(_data, _tag), do: :error

  def is_valid?(data, tag) do
    case verify(data, tag) do
      :ok -> true
      :error -> false
    end
  end
end
