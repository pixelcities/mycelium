defmodule MaestroTest do
  use Maestro.InMemoryEventStoreCase

  doctest Maestro

  import Maestro.TestUtils
  import Commanded.Assertions.EventAssertions

  alias Maestro.{App, Router}
  alias Core.Commands.CreateTask
  alias Core.Events.{
    TransformerCreated,
    TransformerWALUpdated,
    TaskCreated
  }

  test "basic command dispatch" do
    application = Module.concat([App, :ds1])

    task_id = UUID.uuid4()
    :ok = Router.dispatch(%CreateTask{id: task_id, type: "test",task: "task"}, application: application)

    assert_receive_event(application, TaskCreated, fn event ->
      assert event.id == task_id
    end)
  end

  test "process manager is interested in transformers and creates tasks" do
    application = Module.concat([App, :ds1])

    transformer_id = UUID.uuid4()
    transformer_wal = %{
      "identifiers" => %{},
      "values" => %{},
      "transactions" => [
        "SELECT $1"
      ],
      "artifacts" => [
        "[1,2]"
      ]
    }

    create_events(application, "transformers-#{transformer_id}", 0, [
      %TransformerCreated{
        id: transformer_id,
        workspace: "default",
        type: "custom"
      },
      %TransformerWALUpdated{
        id: transformer_id,
        workspace: "default",
        wal: transformer_wal
      }
    ])

    assert_receive_event(application, TaskCreated, fn event ->
      assert event.type == "transformer"
    end)
  end

end
