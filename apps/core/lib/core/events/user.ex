defmodule Core.Events.UserCreated do
  use Commanded.Event,
    version: 2,
    from: Core.Commands.CreateUser,
    with: [:date]

  defimpl Commanded.Event.Upcaster do
    def upcast(%{version: 1} = event, _metadata) do
      Core.Events.UserCreated.new(event, role: "collaborator", version: 2)
    end

    def upcast(event, _metadata), do: event
  end
end

defmodule Core.Events.UserUpdated do
  use Commanded.Event,
    version: 2,
    from: Core.Commands.UpdateUser,
    with: [:date]

  defimpl Commanded.Event.Upcaster do
    def upcast(%{version: 1} = event, _metadata) do
      Core.Events.UserUpdated.new(event, role: "collaborator", version: 2)
    end

    def upcast(event, _metadata), do: event
  end
end

defmodule Core.Events.UserActivitySet do
  use Commanded.Event,
    from: Core.Commands.SetUserActivity,
    with: [:last_active_at, :date]
end

defmodule Core.Events.UserDeleted do
  use Commanded.Event,
    from: Core.Commands.DeleteUser,
    with: [:date]
end

defmodule Core.Events.UserInvited do
  use Commanded.Event,
    from: Core.Commands.InviteUser,
    with: [:date]
end

defmodule Core.Events.InviteAccepted do
  use Commanded.Event,
    from: Core.Commands.AcceptInvite,
    with: [:date]
end

defmodule Core.Events.InviteConfirmed do
  use Commanded.Event,
    from: Core.Commands.ConfirmInvite,
    with: [:date]
end

defmodule Core.Events.InviteCancelled do
  use Commanded.Event,
    from: Core.Commands.CancelInvite,
    with: [:date]
end

