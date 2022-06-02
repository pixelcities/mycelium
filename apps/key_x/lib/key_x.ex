defmodule KeyX do
  @moduledoc """
  Documentation for `KeyX`.
  """

  @app KeyX.Application.get_app()

  alias Core.Commands.ShareSecret


  @doc """
  Forward a secret
  """
  def share_secret(attrs, %{user_id: _user_id} = metadata) do
    share_secret =
      attrs
      |> ShareSecret.new()

    with :ok <- @app.validate_and_dispatch(share_secret, consistency: :strong, application: Module.concat([@app, :ds1]), metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end
end
