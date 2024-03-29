defmodule Core.Events.ConceptCreated do
  use Commanded.Event,
    from: Core.Commands.CreateConcept,
    with: [:date]
end

defmodule Core.Events.ConceptUpdated do
  use Commanded.Event,
    from: Core.Commands.UpdateConcept,
    with: [:date]
end

defmodule Core.Events.ConceptDeleted do
  use Commanded.Event,
    from: Core.Commands.DeleteConcept,
    with: [:date]
end

