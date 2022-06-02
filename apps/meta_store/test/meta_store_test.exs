defmodule MetaStoreTest do
  use MetaStore.InMemoryEventStoreCase

  doctest MetaStore

  import Commanded.Assertions.EventAssertions

  alias MetaStore.{App, Router, Projectors}
  alias MetaStore.Projections.Source
  alias Core.Commands.CreateSource
  alias Core.Events.SourceCreated

  test "ensure source event is published" do
    tenants = Landlord.Registry.get()
    application = Module.concat([App, hd(tenants)])

    source_id = UUID.uuid4()
    :ok = Router.dispatch(%CreateSource{
      id: source_id,
      workspace: "default"
    }, application: application)

    assert_receive_event(application, SourceCreated, fn event ->
      assert event.id == source_id
    end)
  end

end
