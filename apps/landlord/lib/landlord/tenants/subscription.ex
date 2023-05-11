defmodule Landlord.Tenants.Subscription do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Landlord.Tenants.{
    DataSpace,
    Subscription
  }

  @statuses [:active, :trialing, :past_due, :paused, :deleted]

  @primary_key {:subscription_id, :string, autogenerate: false}
  @derive {Jason.Encoder, only: [:checkout_id, :cancel_url, :update_url]}

  schema "subscriptions" do
    field :cancel_url, :string
    field :checkout_id, :string
    field :email, :string
    field :next_bill_date, :date
    field :quantity, :integer
    field :status, Ecto.Enum, values: @statuses
    field :subscription_plan_id, :string
    field :update_url, :string
    field :valid_to, :date

    belongs_to :data_space, DataSpace, type: :binary_id

    timestamps()
  end

  def changeset(subscription, attrs) do
    changes = attrs
      |> Enum.map(fn {key, value} ->
          field = case key do
            "subscription_id" -> :subscription_id
            "cancel_url" -> :cancel_url
            "checkout_id" -> :checkout_id
            "email" -> :email
            "next_bill_date" -> :next_bill_date
            "quantity" -> :quantity
            "new_quantity" -> :quantity
            "status" -> :status
            "subscription_plan_id" -> :subscription_plan_id
            "update_url" -> :update_url
            "paused_from" -> :valid_to
            "cancellation_effective_date" -> :valid_to

            _ -> nil
          end

          {field, value}
      end)
      |> Enum.reject(fn {x, _} -> is_nil(x) end)
      |> Enum.into(%{})

    subscription
    |> cast(changes, Enum.dedup([:subscription_id, :status] ++ Map.keys(changes)))
  end

  def active_subscription_query(%DataSpace{} = data_space) do
    from s in Subscription,
      where: s.data_space_id == ^data_space.id and (
        s.status == :active or (
          s.status in [:paused, :deleted] and s.valid_to > ^Date.utc_today()
        )
      )
  end

  def not_cancelled_subscription_query(%DataSpace{} = data_space) do
    from s in Subscription,
      where: s.data_space_id == ^data_space.id and s.status != :deleted
  end
end
