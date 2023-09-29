defmodule MetaStore.Router do

  use Commanded.Commands.Router

  alias Core.Commands.{
    CreateSource,
    UpdateSource,
    UpdateSourceURI,
    UpdateSourceSchema,
    DeleteSource,
    CreateMetadata,
    UpdateMetadata,
    CreateConcept,
    UpdateConcept,
    DeleteConcept,
    CreateCollection,
    UpdateCollection,
    UpdateCollectionURI,
    UpdateCollectionSchema,
    SetCollectionColor,
    SetCollectionPosition,
    SetCollectionIsReady,
    AddCollectionTarget,
    RemoveCollectionTarget,
    DeleteCollection,
    CreateTransformer,
    UpdateTransformer,
    SetTransformerPosition,
    AddTransformerTarget,
    RemoveTransformerTarget,
    AddTransformerInput,
    UpdateTransformerWAL,
    SetTransformerIsReady,
    SetTransformerError,
    ApproveTransformer,
    DeleteTransformer,
    CreateWidget,
    UpdateWidget,
    SetWidgetPosition,
    SetWidgetIsReady,
    AddWidgetInput,
    PutWidgetSetting,
    PublishWidget,
    DeleteWidget
  }
  alias MetaStore.Aggregates.{
    Source,
    SourceLifespan,
    Metadata,
    Concept,
    ConceptLifespan,
    Collection,
    CollectionLifespan,
    Transformer,
    TransformerLifespan,
    Widget,
    WidgetLifespan
  }

  middleware Core.Middleware.TagCommand
  middleware Core.Middleware.EnrichCommand

  identify(Source, by: :id, prefix: "sources-")
  identify(Metadata, by: :id, prefix: "metadata-")
  identify(Concept, by: :id, prefix: "concepts-")
  identify(Collection, by: :id, prefix: "collections-")
  identify(Transformer, by: :id, prefix: "transformers-")
  identify(Widget, by: :id, prefix: "widgets-")

  dispatch([ CreateSource, UpdateSource, UpdateSourceURI, UpdateSourceSchema, DeleteSource ],
    to: Source,
    lifespan: SourceLifespan
  )
  dispatch([ CreateMetadata, UpdateMetadata ],
    to: Metadata
  )
  dispatch([ CreateConcept, UpdateConcept, DeleteConcept ],
    to: Concept,
    lifespan: ConceptLifespan
  )
  dispatch([ CreateCollection, UpdateCollection, UpdateCollectionURI, UpdateCollectionSchema, SetCollectionColor, SetCollectionPosition, SetCollectionIsReady, AddCollectionTarget, RemoveCollectionTarget, DeleteCollection ],
    to: Collection,
    lifespan: CollectionLifespan
  )
  dispatch([ CreateTransformer, UpdateTransformer, SetTransformerPosition, AddTransformerTarget, RemoveTransformerTarget, AddTransformerInput, UpdateTransformerWAL, SetTransformerIsReady, SetTransformerError, ApproveTransformer, DeleteTransformer ],
    to: Transformer,
    lifespan: TransformerLifespan
  )
  dispatch([ CreateWidget, UpdateWidget, SetWidgetPosition, SetWidgetIsReady, AddWidgetInput, PutWidgetSetting, PublishWidget, DeleteWidget ],
    to: Widget,
    lifespan: WidgetLifespan
  )

end
