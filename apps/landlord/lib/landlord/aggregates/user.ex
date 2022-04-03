defmodule Landlord.Aggregates.User do
  defstruct id: nil,
            email: nil,
            name: nil,
            picture: nil,
            date: nil

  alias Landlord.Aggregates.User
  alias Core.Commands.{CreateUser, UpdateUser}
  alias Core.Events.{UserCreated, UserUpdated}

  @doc """
  Create a user
  """
  def execute(%User{id: nil}, %CreateUser{} = user) do
    UserCreated.new(user, date: NaiveDateTime.utc_now())
  end

  @doc """
  Update a user
  """
  def execute(%User{id: _id}, %UpdateUser{} = update) do
    UserUpdated.new(update, date: NaiveDateTime.utc_now())
  end


  # State mutators

  def apply(%User{} = user, %UserCreated{} = event) do
    %User{user |
      id: event.id,
      email: event.email,
      name: event.name,
      picture: event.picture,
      date: event.date
    }
  end

  def apply(%User{} = user, %UserUpdated{} = event) do
    %User{user |
      email: event.email,
      name: event.name,
      picture: event.picture,
      date: event.date
    }
  end

end
