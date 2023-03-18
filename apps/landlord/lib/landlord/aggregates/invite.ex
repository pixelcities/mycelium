defmodule Landlord.Aggregates.InviteLifespan do
  @behaviour Commanded.Aggregates.AggregateLifespan

  alias Core.Events.{
    InviteConfirmed,
    InviteCancelled
  }

  def after_event(%InviteConfirmed{}), do: :stop
  def after_event(%InviteCancelled{}), do: :hibernate

  def after_event(_event), do: :infinity
  def after_command(_command), do: :infinity
  def after_error(_error), do: :stop
end

defmodule Landlord.Aggregates.Invite do
  defstruct email: nil,
            role: nil,
            id: nil,
            invite_is_pending: true,
            date: nil

  alias Landlord.Aggregates.Invite
  alias Core.Commands.{
    InviteUser,
    AcceptInvite,
    ConfirmInvite,
    CancelInvite
  }
  alias Core.Events.{
    UserInvited,
    InviteAccepted,
    InviteConfirmed,
    InviteCancelled
  }

  def execute(%Invite{email: nil}, %InviteUser{} = user) do
    UserInvited.new(user, date: NaiveDateTime.utc_now())
  end

  def execute(%Invite{}, %InviteUser{}), do: {:error, :user_already_invited}

  def execute(%Invite{email: _email}, %AcceptInvite{} = command) do
    InviteAccepted.new(command, date: NaiveDateTime.utc_now())
  end

  def execute(%Invite{email: _email}, %ConfirmInvite{} = command) do
    InviteConfirmed.new(command, date: NaiveDateTime.utc_now())
  end

  def execute(%Invite{email: _email}, %CancelInvite{} = command) do
    InviteCancelled.new(command, date: NaiveDateTime.utc_now())
  end


  # State mutators

  def apply(%Invite{} = invite, %UserInvited{} = event) do
    %Invite{invite |
      email: event.email,
      role: event.role,
      invite_is_pending: true,
      date: event.date
    }
  end

  def apply(%Invite{} = invite, %InviteAccepted{} = event) do
    %Invite{invite |
      id: event.id,
      invite_is_pending: false,
      date: event.date
    }
  end

  def apply(%Invite{} = invite, %InviteConfirmed{} = _event), do: invite
  def apply(%Invite{} = invite, %InviteCancelled{} = _event), do: invite

end
