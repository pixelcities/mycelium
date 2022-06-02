defmodule Maestro.Managers.TransformerTaskProcessManager do
  @moduledoc """
  Create and manage tasks that apply transformer operations

  Whenever a transformer is created or updated, a new output collection
  needs to be generated. This process manager will listen for such events
  and ensure that tasks are scheduled that will compute the fragments of
  these collections.

  TODO: handle downstream transformers
  """

  use Commanded.ProcessManagers.ProcessManager,
    name: __MODULE__

  @derive Jason.Encoder
  defstruct [
    :id,
    :transformer,
    # :wants_collection,
    :has_collection,
    :task_id
  ]

  alias Maestro.Managers.TransformerTaskProcessManager
  alias Core.Commands.CreateTask
  alias Core.Events.{
    TransformerCreated,
    TransformerWALUpdated
  }

  # Process routing

  def interested?(%TransformerCreated{id: id}), do: {:start, id}
  def interested?(%TransformerWALUpdated{id: id}), do: {:continue, id}
  def interested?(_event), do: false

  # Command dispatch


  # TODO: Create the collection, uri, and link the two components
  def handle(%TransformerTaskProcessManager{has_collection: false} = pm, %TransformerWALUpdated{wal: wal} = _event) do
    %CreateTask{
      id: UUID.uuid4(),
      type: "transformer",
      task: %{
        "instruction" => "compute_fragment",
        "transformer_id" => pm.id,
        "columns" => [],
        "wal" => wal
      }
    }
  end

  @doc """
  Create unassigned task

  An unassigned task will be materialized and queued for future assignments when a suitable
  worker comes online.

  Note that one worker may not have enough ownership to create the full output collection.
  Task assignment will instead take care of duplicating the task as many times as needed
  so that all fragments make up a full collection.
  """
  def handle(%TransformerTaskProcessManager{has_collection: true} = pm, %TransformerWALUpdated{wal: wal} = _event) do
    %CreateTask{
      id: UUID.uuid4(),
      type: "transformer",
      task: %{
        "instruction" => "compute_fragment",
        "transformer_id" => pm.id,
        "columns" => [],
        "wal" => wal
      }
    }
  end

  # State mutators

  def apply(%TransformerTaskProcessManager{} = pm, %TransformerCreated{} = event) do
    %TransformerTaskProcessManager{pm |
      id: event.id,
      transformer: event,
      has_collection: false
    }
  end

end
