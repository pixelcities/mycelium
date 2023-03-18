defmodule Landlord.Router do

  use Commanded.Commands.Router

  alias Core.Commands.{
    CreateUser,
    UpdateUser,
    SetUserActivity,
    InviteUser,
    AcceptInvite,
    ConfirmInvite,
    CancelInvite,
    SendUserNotification,
    MarkNotificationRead
  }
  alias Landlord.Aggregates.{User, Invite, InviteLifespan, Notification}

  identify(User, by: :id, prefix: "users-")
  identify(Invite, by: :email, prefix: "invites-")

  dispatch([ CreateUser, UpdateUser, SetUserActivity ], to: User)
  dispatch([ InviteUser, AcceptInvite, ConfirmInvite, CancelInvite ], to: Invite, lifespan: InviteLifespan)
  dispatch(SendUserNotification, to: Notification, identity: :receiver, identity_prefix: "notifications-")
  dispatch(MarkNotificationRead, to: Notification, identity: :read_by, identity_prefix: "notifications-")
end
