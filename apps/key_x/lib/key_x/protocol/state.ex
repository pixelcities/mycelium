defmodule KeyX.Protocol.State do
  use Ecto.Schema
  import Ecto.Changeset

  alias KeyX.Protocol.State

  @derive {Jason.Encoder, only: [:user_id, :state]}
  schema "state" do
    field :user_id, :binary_id
    field :state, :string
    field :message_id, :integer
    field :message_ids, {:array, :integer}
    field :in_transit, {:array, :integer}

    timestamps()
  end

  def new(user_id) do
    %State{
      user_id: user_id,
      message_id: 0,
      message_ids: [],
      in_transit: []
    }
  end

  def update_state(changeset, %{"state" => state, "message_ids" => message_ids}) do
    message_ids = Enum.reject(message_ids, fn id -> id < changeset.message_id end)

    {committed, message_id} =
      message_ids ++ changeset.message_ids
      |> Enum.sort()
      |> Enum.dedup()
      |> Enum.flat_map_reduce(changeset.message_id, fn id, acc ->
        if id <= acc+1, do: {[id], id}, else: {:halt, acc}
      end)

    attrs = %{
      state: state,
      message_id: message_id,
      message_ids: Enum.uniq(changeset.message_ids ++ message_ids) -- committed,
      in_transit: changeset.in_transit -- committed
    }

    changeset
    |> cast(attrs, [:state, :message_id, :message_ids, :in_transit])
  end

  def message_sent(changeset, message_id) do
    change(changeset, in_transit: changeset.in_transit ++ [message_id])
  end
end
