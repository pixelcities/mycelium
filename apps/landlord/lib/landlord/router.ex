defmodule Landlord.Router do

  use Commanded.Commands.Router

  alias Core.Commands.{CreateUser, UpdateUser}
  alias Landlord.Aggregates.User

  identify(User, by: :id, prefix: "users-")

  dispatch([CreateUser, UpdateUser],
    to: User
  )

end
