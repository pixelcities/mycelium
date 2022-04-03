defmodule Core.Events.SecretShared do
  use Commanded.Event,
    from: Core.Commands.ShareSecret,
    with: [:date]
end
