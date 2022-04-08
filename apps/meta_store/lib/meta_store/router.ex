defmodule MetaStore.Router do

  use Commanded.Commands.Router

  alias Core.Commands.{
    CreateSource,
    UpdateSource,
    CreateMetadata,
    UpdateMetadata,
    CreateCollection,
    UpdateCollection,
    SetCollectionPosition,
    AddCollectionTarget,
    CreateTransformer,
    UpdateTransformer,
    SetTransformerPosition,
    AddTransformerTarget,
    AddTransformerInput,
    UpdateTransformerWAL
  }
  alias MetaStore.Aggregates.{Source, Metadata, Collection, Transformer}

  identify(Source, by: :id, prefix: "sources-")
  identify(Metadata, by: :id, prefix: "metadata-")
  identify(Collection, by: :id, prefix: "collections-")
  identify(Transformer, by: :id, prefix: "transformers-")

  dispatch([ CreateSource, UpdateSource ], to: Source)
  dispatch([ CreateMetadata, UpdateMetadata ], to: Metadata)
  dispatch([ CreateCollection, UpdateCollection, SetCollectionPosition, AddCollectionTarget ], to: Collection)
  dispatch([ CreateTransformer, UpdateTransformer, SetTransformerPosition, AddTransformerTarget, AddTransformerInput, UpdateTransformerWAL ], to: Transformer)

end
