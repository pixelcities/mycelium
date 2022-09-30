defmodule MetaStore.Aggregates.Concept do
  defstruct id: nil,
            workspace: nil,
            concept: nil,
            date: nil

  alias MetaStore.Aggregates.Concept
  alias Core.Commands.{CreateConcept, UpdateConcept}
  alias Core.Events.{ConceptCreated, ConceptUpdated}


  def execute(%Concept{id: nil}, %CreateConcept{} = concept) do
    ConceptCreated.new(concept, date: NaiveDateTime.utc_now())
  end

  def execute(%Concept{} = concept, %UpdateConcept{} = update)
    when concept.workspace == update.workspace
  do
    ConceptUpdated.new(update, date: NaiveDateTime.utc_now())
  end


  # State mutators

  def apply(%Concept{} = concept, %ConceptCreated{} = event) do
    %Concept{concept |
      id: event.id,
      workspace: event.workspace,
      concept: event.concept,
      date: event.date
    }
  end

  def apply(%Concept{} = concept, %ConceptUpdated{} = event) do
    %Concept{concept |
      concept: event.concept,
      date: event.date
    }
  end

end
