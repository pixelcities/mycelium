defmodule Core.Events.MPCCreated do
  use Commanded.Event,
    from: Core.Commands.CreateMPC,
    with: [:date]
end

defmodule Core.Events.MPCPartialShared do
  use Commanded.Event,
    from: Core.Commands.ShareMPCPartial,
    with: [:date]
end

defmodule Core.Events.MPCResultShared do
  use Commanded.Event,
    from: Core.Commands.ShareMPCResult,
    with: [:date]
end

