defmodule KeyX.TrialAgent do
  @moduledoc """
  TrialAgent manages secrets for the trial data space

  Data spaces require a metadata key, which needs to be shared
  with new users. Normally, this is shared by the user inviting
  a new collaborator, but in the case of the trial data space there
  is no such user.

  In order to best simulate real behaviour, this trial agent actually
  stores the metadata key in the KeyStore, although the initial key
  id is static to simplify state. It will share the manifest key just
  like a real user would using ShareSecret.

  This agent is not to be used with real data spaces.
  """

  alias KeyX.{KeyStore, Protocol}
  alias Landlord.Accounts

  @config Application.get_env(:key_x, KeyX.TrialAgent)

  def create_manifest_key() do
    user = Accounts.get_user_by_email(@config[:email])

    secret = @config[:secret_key] |> Base.decode16!(case: :lower)
    iv = :crypto.strong_rand_bytes(16)

    rand_plaintext = :crypto.strong_rand_bytes(32) |> Base.encode16(case: :lower)
    encrypted = :crypto.crypto_one_time(:aes_128_cbc, secret, iv, rand_plaintext, true)

    {:ok, key} = KeyStore.upsert_key(@config[:key_id], user, %{
      ciphertext: "#{Base.encode64(iv, padding: true)}:#{Base.encode64(encrypted, padding: true)}"
    })

    key.key_id
  end

  def get_manifest_key() do
    user = Accounts.get_user_by_email(@config[:email])

    secret = @config[:secret_key] |> Base.decode16!(case: :lower)
    {:ok, key} = KeyStore.get_key_by_id_and_user(@config[:key_id], user)
    [iv, encrypted] = String.split(key.ciphertext, ":")

    :crypto.crypto_one_time(:aes_128_cbc, secret, Base.decode64!(iv, padding: true), Base.decode64!(encrypted, padding: true), false)
  end

  def share_manifest_key(receiver, ds_id) do
    key = get_manifest_key()
    user = Accounts.get_user_by_email(@config[:email])

    bundle_id = Protocol.get_max_bundle_id_by_user!(receiver)
    bundle = Protocol.pop_bundle(receiver.id, bundle_id)

    ciphertext = Protocol.Agent.encrypt_once(receiver.id, bundle, key)

    KeyX.share_secret(%{
      key_id: @config[:key_id],
      owner: user.id,
      receiver: receiver.id,
      ciphertext: ciphertext
    }, %{
      user_id: user.id,
      ds_id: ds_id
    })
  end
end

