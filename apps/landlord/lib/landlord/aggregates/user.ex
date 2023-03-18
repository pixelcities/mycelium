defmodule Landlord.Aggregates.User do
  defstruct id: nil,
            email: nil,
            role: nil,
            name: nil,
            picture: nil,
            last_active_at: nil,
            date: nil

  alias Landlord.Aggregates.User
  alias Core.Commands.{
    CreateUser,
    UpdateUser,
    SetUserActivity
  }
  alias Core.Events.{
    UserCreated,
    UserUpdated,
    UserActivitySet
  }


  def execute(%User{id: nil}, %CreateUser{} = user) do
    UserCreated.new(user, date: NaiveDateTime.utc_now())
  end

  def execute(%User{}, %CreateUser{}), do: {:error, :user_already_created}

  def execute(%User{id: _id}, %UpdateUser{} = update) do
    UserUpdated.new(update, date: NaiveDateTime.utc_now())
  end

  def execute(%User{id: _id}, %SetUserActivity{} = command) do
    UserActivitySet.new(command,
      last_active_at: NaiveDateTime.utc_now(),
      date: NaiveDateTime.utc_now()
    )
  end


  # State mutators

  def apply(%User{} = user, %UserCreated{} = event) do
    %User{user |
      id: event.id,
      email: event.email,
      role: event.role,
      name: event.name,
      picture: event.picture,
      last_active_at: event.last_active_at,
      date: event.date
    }
  end

  def apply(%User{} = user, %UserUpdated{} = event) do
    %User{user |
      id: event.id,
      email: event.email,
      role: event.role,
      name: event.name,
      picture: event.picture,
      last_active_at: event.last_active_at,
      date: event.date
    }
  end

  def apply(%User{} = user, %UserActivitySet{} = event) do
    %User{user |
      id: event.id,
      last_active_at: event.last_active_at,
      date: event.date
    }
  end

end
