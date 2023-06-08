defmodule MetaStoreTest do
  use MetaStore.InMemoryEventStoreCase
  use PgTestCase,
    otp_app: :meta_store,
    repo: MetaStore.Repo,
    prefix: :test

  setup_all [:initdb, :migrations]
  setup :event_store

  doctest MetaStore

  import Commanded.Assertions.EventAssertions

  alias MetaStore.{App, Router}
  alias Core.Commands.CreateSource
  alias Core.Events.SourceCreated

  test "ensure source event is published", _context do
    tenants = Landlord.Tenants.get!()
    application = Module.concat([App, hd(tenants)])

    source_id = UUID.uuid4()
    :ok = Router.dispatch(
      %CreateSource{
        id: source_id,
        workspace: "default",
        uri: ["", ""]
      },
      metadata: %{"ds_id" => :test},
      application: application
    )

    assert_receive_event(application, SourceCreated, fn event ->
      assert event.id == source_id
    end)
  end

end
