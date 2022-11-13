defmodule Core.Events.ContentCreated do
  use Commanded.Event,
    from: Core.Commands.CreateContent,
    with: [:date, :ds]
end

defmodule Core.Events.ContentUpdated do
  use Commanded.Event,
    from: Core.Commands.UpdateContent,
    with: [:date]
end

defmodule Core.Events.ContentDeleted do
  use Commanded.Event,
    from: Core.Commands.DeleteContent,
    with: [:date]
end

defmodule Core.Events.PageCreated do
  use Commanded.Event,
    from: Core.Commands.CreatePage,
    with: [:date, :ds]
end

defmodule Core.Events.PageUpdated do
  use Commanded.Event,
    from: Core.Commands.UpdatePage,
    with: [:date]
end

defmodule Core.Events.PageDeleted do
  use Commanded.Event,
    from: Core.Commands.DeletePage,
    with: [:date]
end
