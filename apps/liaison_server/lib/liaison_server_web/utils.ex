defmodule LiaisonServerWeb.Utils do
  @moduledoc """
  Various utils
  """

  import Ecto.Changeset

  @config Application.get_env(:liaison_server, LiaisonServerWeb)[:from]

  @doc """
  Translate a changeset to a map with error messages
  """
  def changeset_error(changeset) do
    traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end


  @doc """
  Returns a URL with the host pointing to the front-end
  """
  def get_external_host() do
    %URI{
      scheme: @config[:scheme],
      host: @config[:host],
      port: @config[:port]
    }
  end
end

