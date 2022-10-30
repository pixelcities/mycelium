defmodule ContentServer do
  @moduledoc """
  Documentation for `ContentServer`.
  """

  @app ContentServer.Application.get_app()

  import Ecto.Query, warn: false

  alias ContentServer.Repo
  alias ContentServer.Projections.Content
  alias Core.Commands.{
    CreateContent,
    UpdateContent,
    DeleteContent
  }


  ## Database getters

  def get_content!(id, opts \\ []) do
    tenant = Keyword.fetch!(opts, :tenant)

    Repo.one((from t in Content,
      where: t.id == ^id
    ), prefix: tenant)
  end


  ## Commands

  @doc """
  Create a content block

  User content can either be static or reference a widget.
  In both cases, the content will be served by ContentServerWeb.
  """
  def create_content(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(CreateContent.new(attrs), metadata)
  end

  def update_content(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(UpdateContent.new(attrs), metadata)
  end

  def delete_content(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(DeleteContent.new(attrs), metadata)
  end

  defp handle_dispatch(command, metadata) do
    ds_id = Map.get(metadata, :ds_id, :ds1)

    with :ok <- @app.validate_and_dispatch(command, consistency: :strong, application: Module.concat(@app, ds_id), metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end

end
