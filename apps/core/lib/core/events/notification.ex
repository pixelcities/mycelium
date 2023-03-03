defmodule Core.Events.UserNotificationSent do
  use Commanded.Event,
    from: Core.Commands.SendUserNotification,
    with: [:date]
end

defmodule Core.Events.NotificationRead do
  use Commanded.Event,
    from: Core.Commands.MarkNotificationRead,
    with: [:date]
end

