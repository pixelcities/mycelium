defmodule Core.Events.CollectionCreated do
  use Commanded.Event,
    from: Core.Commands.CreateCollection,
    with: [:date, :ds]
end

defmodule Core.Events.CollectionUpdated do
  use Commanded.Event,
    from: Core.Commands.UpdateCollection,
    with: [:date],
    drop: [:__metadata__]
end

defmodule Core.Events.CollectionSchemaUpdated do
  use Commanded.Event,
    from: Core.Commands.UpdateCollectionSchema,
    with: [:date],
    drop: [:__metadata__]
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

defmodule Core.Events.CollectionColorSet do
  use Commanded.Event,
    from: Core.Commands.SetCollectionColor,
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
    with: [:date, :type, :uri],
    drop: [:__metadata__]
end

defmodule Core.Events.TransformerCreated do
  use Commanded.Event,
    from: Core.Commands.CreateTransformer,
    with: [:date, :ds]
end

defmodule Core.Events.TransformerUpdated do
  use Commanded.Event,
    from: Core.Commands.UpdateTransformer,
    with: [:date],
    drop: [:__metadata__]
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
    with: [:date],
    drop: [:__metadata__]
end

defmodule Core.Events.TransformerIsReadySet do
  use Commanded.Event,
    from: Core.Commands.SetTransformerIsReady,
    with: [:date]
end

defmodule Core.Events.TransformerErrorSet do
  use Commanded.Event,
    from: Core.Commands.SetTransformerError,
    with: [:date]
end

defmodule Core.Events.TransformerDeleted do
  use Commanded.Event,
    from: Core.Commands.DeleteTransformer,
    with: [:date]
end

defmodule Core.Events.WidgetCreated do
  use Commanded.Event,
    from: Core.Commands.CreateWidget,
    with: [:date, :ds]
end

defmodule Core.Events.WidgetUpdated do
  use Commanded.Event,
    from: Core.Commands.UpdateWidget,
    with: [:date]
end

defmodule Core.Events.WidgetPositionSet do
  use Commanded.Event,
    from: Core.Commands.SetWidgetPosition,
    with: [:date]
end

defmodule Core.Events.WidgetIsReadySet do
  use Commanded.Event,
    from: Core.Commands.SetWidgetIsReady,
    with: [:date]
end

defmodule Core.Events.WidgetInputAdded do
  use Commanded.Event,
    from: Core.Commands.AddWidgetInput,
    with: [:date]
end

defmodule Core.Events.WidgetSettingPut do
  use Commanded.Event,
    from: Core.Commands.PutWidgetSetting,
    with: [:date]
end

defmodule Core.Events.WidgetPublished do
  use Commanded.Event,
    from: Core.Commands.PublishWidget,
    with: [:date]
end

defmodule Core.Events.WidgetDeleted do
  use Commanded.Event,
    from: Core.Commands.DeleteWidget,
    with: [:date]
end

