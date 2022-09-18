defmodule MetaStore.Router do

  use Commanded.Commands.Router

  alias Core.Commands.{
    CreateSource,
    UpdateSource,
    DeleteSource,
    CreateMetadata,
    UpdateMetadata,
    CreateCollection,
    UpdateCollection,
    UpdateCollectionSchema,
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
    DeleteTransformer
  }
  alias MetaStore.Aggregates.{
    Source,
    SourceLifespan,
    Metadata,
    Collection,
    CollectionLifespan,
    Transformer,
    TransformerLifespan
  }

  identify(Source, by: :id, prefix: "sources-")
  identify(Metadata, by: :id, prefix: "metadata-")
  identify(Collection, by: :id, prefix: "collections-")
  identify(Transformer, by: :id, prefix: "transformers-")

  dispatch([ CreateSource, UpdateSource, DeleteSource ],
    to: Source,
    lifespan: SourceLifespan
  )
  dispatch([ CreateMetadata, UpdateMetadata ],
    to: Metadata
  )
  dispatch([ CreateCollection, UpdateCollection, UpdateCollectionSchema, SetCollectionPosition, SetCollectionIsReady, AddCollectionTarget, RemoveCollectionTarget, DeleteCollection ],
    to: Collection,
    lifespan: CollectionLifespan
  )
  dispatch([ CreateTransformer, UpdateTransformer, SetTransformerPosition, AddTransformerTarget, RemoveTransformerTarget, AddTransformerInput, UpdateTransformerWAL, DeleteTransformer ],
    to: Transformer,
    lifespan: TransformerLifespan
  )

end
