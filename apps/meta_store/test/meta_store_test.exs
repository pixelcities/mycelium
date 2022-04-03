defmodule MetaStoreTest do
  use MetaStore.InMemoryEventStoreCase

  import Commanded.Assertions.EventAssertions

  alias MetaStore.{App, Router}
  alias Core.Commands.CreateSource
  alias Core.Events.SourceCreated

  test "ensure source event is published" do
    tenants = Landlord.Registry.get()
    application = Module.concat([App, hd(tenants)])

    :ok = Router.dispatch(%CreateSource{source_id: 1, owner: "me"}, application: application)

    assert_receive_event(application, SourceCreated, fn event ->
      assert event.source_id == 1
    end)
  end

end
