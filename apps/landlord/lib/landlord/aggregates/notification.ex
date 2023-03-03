defmodule Landlord.Aggregates.Notification do
  defstruct user_id: nil,
            notifications: %{}

  alias Landlord.Aggregates.Notification
  alias Core.Commands.{SendUserNotification, MarkNotificationRead}
  alias Core.Events.{UserNotificationSent, NotificationRead}


  def execute(%Notification{notifications: notifications}, %SendUserNotification{} = command) do
    unless Map.has_key?(notifications, command.id) do
      UserNotificationSent.new(command, date: NaiveDateTime.utc_now())
    else
      {:error, :notification_id_already_exists}
    end
  end

  def execute(%Notification{notifications: notifications}, %MarkNotificationRead{} = command) do
    if Map.has_key?(notifications, command.id) do
      NotificationRead.new(command, date: NaiveDateTime.utc_now())
    else
      {:error, :notification_does_not_exist}
    end
  end


  # State mutators

  def apply(%Notification{notifications: notifications} = state, %UserNotificationSent{} = event) do
    %Notification{state |
      user_id: event.receiver,
      notifications: Map.put(notifications, event.id, %{
        id: event.id,
        type: event.type,
        message: event.message,
        receiver: event.receiver,
        is_urgent: event.is_urgent,
        date: event.date
      })
    }
  end

  def apply(%Notification{notifications: notifications} = state, %NotificationRead{} = event) do
    %Notification{state |
      notifications: Map.delete(notifications, event.id)
    }
  end

end
