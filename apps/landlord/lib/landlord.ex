defmodule Landlord do
  @moduledoc """
  Documentation for `Landlord`.
  """

  @app Landlord.Application.get_app()

  alias Core.Commands.{CreateUser, UpdateUser}


  @doc """
  Create a user
  """
  def create_user(attrs, %{"user_id" => _user_id, "ds_id" => ds_id} = metadata) do
    command = CreateUser.new(attrs)

    with :ok <- @app.validate_and_dispatch(command, consistency: :strong, application: Module.concat(@app, ds_id), metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end

  @doc """
  Update a user
  """
  def update_user(attrs, %{"user_id" => _user_id, "ds_id" => ds_id} = metadata) do
    command = UpdateUser.new(attrs)

    with :ok <- @app.validate_and_dispatch(command, consistency: :strong, application: Module.concat(@app, ds_id), metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end


end
