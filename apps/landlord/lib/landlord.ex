defmodule Landlord do
  @moduledoc """
  Documentation for `Landlord`.
  """

  @app MetaStore.Application.get_app()

  alias Core.Commands.{CreateUser, UpdateUser}


  @doc """
  Create a user
  """
  def create_user(attrs, %{user_id: _user_id} = metadata) do
    command =
      attrs
      |> CreateUser.new()

    with :ok <- @app.validate_and_dispatch(command, consistency: :strong, application: Module.concat([@app, :ds1]), metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end

  @doc """
  Update a user
  """
  def update_user(attrs, %{user_id: _user_id} = metadata) do
    command =
      attrs
      |> UpdateUser.new()

    with :ok <- @app.validate_and_dispatch(command, consistency: :strong, application: Module.concat([@app, :ds1]), metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end

end
