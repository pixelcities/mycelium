defmodule LiaisonServerWeb.Utils do
  @moduledoc """
  Various utils
  """

  import Ecto.Changeset

  @host %URI{scheme: "https", host: "datagarden.app"}

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
  def get_external_host() do @host end
end

