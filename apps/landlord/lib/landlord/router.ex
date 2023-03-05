defmodule Landlord.Router do

  use Commanded.Commands.Router

  alias Core.Commands.{
    CreateUser,
    UpdateUser,
    SetUserActivity,
    InviteUser,
    SendUserNotification,
    MarkNotificationRead
  }
  alias Landlord.Aggregates.{User, Notification}

  identify(User, by: :id, prefix: "users-")

  dispatch([ CreateUser, UpdateUser, SetUserActivity, InviteUser ], to: User)
  dispatch(SendUserNotification, to: Notification, identity: :receiver, identity_prefix: "notifications-")
  dispatch(MarkNotificationRead, to: Notification, identity: :read_by, identity_prefix: "notifications-")
end
