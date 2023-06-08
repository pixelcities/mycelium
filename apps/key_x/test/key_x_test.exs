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

  test "state can keep track of committed messages" do
    user = %User{id: Ecto.UUID.generate()}

    initial_state = %{
      "state" => "state",
      "message_ids" => [1]
    }
    {:ok, _} = Protocol.upsert_state(user, initial_state)

    batch_1 = %{
      "state" => "state",
      "message_ids" => [2,3,4]
    }
    {:ok, changeset} = Protocol.upsert_state(user, batch_1)

    assert changeset.message_id == 4
    assert changeset.message_ids == []

    unordered_batch = %{
      "state" => "state",
      "message_ids" => [3,6,5]
    }
    {:ok, changeset} = Protocol.upsert_state(user, unordered_batch)

    assert changeset.message_id == 6

    # The real test, this commit is missing one message
    out_of_order_batch = %{
      "state" => "state",
      "message_ids" => [6,7,9,10]
    }
    {:ok, changeset} = Protocol.upsert_state(user, out_of_order_batch)

    # The message_id snapshot can only save up to message 7
    assert changeset.message_id == 7
    assert changeset.message_ids == [9, 10]

    # And finally, the missing message arrives
    final_batch = %{
      "state" => "state",
      "message_ids" => [8]
    }
    {:ok, changeset} = Protocol.upsert_state(user, final_batch)

    assert changeset.message_id == 10
    assert changeset.message_ids == []
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

    wait_for_event(application, SecretShared, fn event -> event.message_id == 1 end)

    state = Protocol.get_state_by_user!(user)

    assert state.in_transit == [1]
  end
end
