defmodule ContentServer do
  @moduledoc """
  Documentation for `ContentServer`.
  """

  @app ContentServer.Application.get_app()

  import Ecto.Query, warn: false

  alias ContentServer.Repo
  alias ContentServer.Projections.{
    Content,
    Page
  }
  alias Core.Commands.{
    CreateContent,
    UpdateContent,
    UpdateContentDraft,
    DeleteContent,
    CreatePage,
    UpdatePage,
    DeletePage
  }


  ## Database getters

  def get_page!(id, opts \\ []) do
    tenant = Keyword.fetch!(opts, :tenant)

    Repo.one((from t in Page,
      where: t.id == ^id,
      preload: [:content]
    ), prefix: tenant)
  end

  def get_content!(id, opts \\ []) do
    tenant = Keyword.fetch!(opts, :tenant)

    Repo.one((from t in Content,
      where: t.id == ^id
    ), prefix: tenant)
  end

  def get_content_by_widget_id(id, opts \\ []) do
    tenant = Keyword.fetch!(opts, :tenant)

    Repo.all((from t in Content,
      where: t.widget_id == ^id
    ), prefix: tenant)
  end

  def get_content_by_page_id(id, opts \\ []) do
    tenant = Keyword.fetch!(opts, :tenant)

    Repo.all((from t in Content,
      where: t.page_id == ^id
    ), prefix: tenant)
  end


  ## Commands

  def create_page(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(CreatePage.new(attrs), metadata)
  end

  def update_page(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(UpdatePage.new(attrs), metadata)
  end

  def delete_page(%{"id" => id} = attrs, %{user_id: _user_id} = metadata) do
    ds_id = Map.get(metadata, :ds_id, :ds1)

    page = get_page!(id, tenant: ds_id)

    delete_content_cmds = Enum.map(page.content, fn c -> DeleteContent.new(%{:id => c.id, :workspace => c.workspace}) end)
    delete_self_cmd = DeletePage.new(attrs)

    Enum.reduce_while(delete_content_cmds ++ [delete_self_cmd], {:ok, :done}, fn command, _acc ->
      reply = @app.validate_and_dispatch(command, consistency: :strong, application: Module.concat(@app, ds_id), metadata: metadata)

      if reply == :ok do
        {:cont, {:ok, :done}}
      else
        {:halt, reply}
      end
    end)
  end

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

  def update_content_draft(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(UpdateContentDraft.new(attrs), metadata)
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
