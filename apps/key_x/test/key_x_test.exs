defmodule KeyXTest do
  use KeyX.InMemoryEventStoreCase
  use PgTestCase,
    otp_app: :key_x,
    repo: KeyX.Repo

  setup_all [:initdb, :migrations]
  setup :event_store

  doctest KeyX

  import Commanded.Assertions.EventAssertions

  alias Landlord.Accounts.User
  alias Core.Commands.ShareSecret
  alias Core.Events.SecretShared
  alias KeyX.{App, Router, Protocol}

  test "state can be upserted", _context do
    user = %User{id: Ecto.UUID.generate()}

    # Insert
    {:ok, changeset} = Protocol.upsert_state(user, %{"state" => "state_0", "message_ids" => []})
    assert changeset.state == "state_0"

    # Update
    {:ok, changeset} = Protocol.upsert_state(user, %{"state" => "state_1", "message_ids" => []})
    assert changeset.state == "state_1"
  end

  test "old state messages can be retrieved" do
    user = %User{id: Ecto.UUID.generate()}
    {:ok, %{id: state_id}} = Protocol.upsert_state(user, %{"state" => "state_0", "message_ids" => []})

    # Created some "in-transit" messages
    for _ <- 1..3, do:  KeyX.Repo.insert(%Protocol.StateMessages{state_id: state_id, message_id: Ecto.UUID.generate()})

    message_ids = Protocol.get_old_messages_by_user(user, 0) # Set to zero minutes ago to just retrieve everything

    assert length(message_ids) == 3

    # After committing them there should be none left in transit
    {:ok, changeset} = Protocol.upsert_state(user, %{"state" => "state_1", "message_ids" => message_ids})
    assert changeset.state == "state_1"
    assert length(Protocol.get_old_messages_by_user(user, 0)) == 0
  end

  test "state projector keeps track of in transit messages" do
    tenants = Landlord.Tenants.get!()
    application = Module.concat([App, hd(tenants)])

    user = %User{id: Ecto.UUID.generate()}

    :ok = Router.dispatch(
      %ShareSecret{
        key_id: Ecto.UUID.generate(),
        owner: Ecto.UUID.generate(),
        receiver: user.id,
        ciphertext: "message"
      },
      metadata: %{"ds_id" => :test},
      application: application,
      consistency: :strong
    )

    wait_for_event(application, SecretShared, fn _event -> true end)

    in_transit = length(Protocol.get_old_messages_by_user(user, 0))

    assert in_transit == 1
  end
end
