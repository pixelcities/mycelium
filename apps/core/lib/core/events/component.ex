defmodule Core.Events.CollectionCreated do
  use Commanded.Event,
    from: Core.Commands.CreateCollection,
    with: [:date, :ds]
end

defmodule Core.Events.CollectionUpdated do
  use Commanded.Event,
    from: Core.Commands.UpdateCollection,
    with: [:date]
end

defmodule Core.Events.CollectionSchemaUpdated do
  use Commanded.Event,
    from: Core.Commands.UpdateCollectionSchema,
    with: [:date]
end

defmodule Core.Events.CollectionTargetAdded do
  use Commanded.Event,
    from: Core.Commands.AddCollectionTarget,
    with: [:date]
end

defmodule Core.Events.CollectionTargetRemoved do
  use Commanded.Event,
    from: Core.Commands.RemoveCollectionTarget,
    with: [:date]
end

defmodule Core.Events.CollectionPositionSet do
  use Commanded.Event,
    from: Core.Commands.SetCollectionPosition,
    with: [:date]
end

defmodule Core.Events.CollectionIsReadySet do
  use Commanded.Event,
    from: Core.Commands.SetCollectionIsReady,
    with: [:date]
end

defmodule Core.Events.CollectionDeleted do
  use Commanded.Event,
    from: Core.Commands.DeleteCollection,
    with: [:date, :type, :uri]
end

defmodule Core.Events.TransformerCreated do
  use Commanded.Event,
    from: Core.Commands.CreateTransformer,
    with: [:date, :ds]
end

defmodule Core.Events.TransformerUpdated do
  use Commanded.Event,
    from: Core.Commands.UpdateTransformer,
    with: [:date]
end

defmodule Core.Events.TransformerTargetAdded do
  use Commanded.Event,
    from: Core.Commands.AddTransformerTarget,
    with: [:date]
end

defmodule Core.Events.TransformerTargetRemoved do
  use Commanded.Event,
    from: Core.Commands.RemoveTransformerTarget,
    with: [:date]
end

defmodule Core.Events.TransformerPositionSet do
  use Commanded.Event,
    from: Core.Commands.SetTransformerPosition,
    with: [:date]
end

defmodule Core.Events.TransformerInputAdded do
  use Commanded.Event,
    from: Core.Commands.AddTransformerInput,
    with: [:date]
end

defmodule Core.Events.TransformerWALUpdated do
  use Commanded.Event,
    from: Core.Commands.UpdateTransformerWAL,
    with: [:date]
end

defmodule Core.Events.TransformerDeleted do
  use Commanded.Event,
    from: Core.Commands.DeleteTransformer,
    with: [:date]
end

