defmodule KeyX do
  @moduledoc """
  Documentation for `KeyX`.
  """

  @app KeyX.Application.get_app()

  alias KeyX.KeyStore
  alias Core.Commands.ShareSecret


  @doc """
  Forward a secret
  """
  def share_secret(attrs, %{"user_id" => user_id, "ds_id" => ds_id} = metadata) do
    share_secret =
      attrs
      |> ShareSecret.new()
      |> ShareSecret.validate_owner(user_id)
      |> ShareSecret.validate_key_id(&KeyStore.get_key_by_id_and_user(&1, user_id), user_id)

    with :ok <- @app.validate_and_dispatch(share_secret, consistency: :strong, application: Module.concat(@app, ds_id), metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end
end
