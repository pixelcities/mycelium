defmodule Landlord.Tenants.Subscription do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Landlord.Tenants.{
    DataSpace,
    Subscription
  }

  @subscriptions_enabled Application.compile_env(:landlord, :subscriptions)[:enabled]

  @statuses [:active, :trialing, :past_due, :paused, :deleted]

  @primary_key {:subscription_id, :string, autogenerate: false}
  @derive {Jason.Encoder, only: [:subscription_id, :status, :quantity, :cancel_url, :update_url, :valid_to]}

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

  @doc """
  Get a where statement to determine if a subscription is active

  Returns a tuple with named binding to be used in the parent query and
  the where clause.
  """
  def active_subscription_clause do
    if @subscriptions_enabled do
      {:subscription, dynamic([subscription: s],
        s.status == :active or (
          s.status in [:paused, :deleted] and s.valid_to > ^Date.utc_today()
        )
      )}
    else
      {:subscription, true}
    end
  end

  def checkout_query(checkout_id) do
    {identifier, subscription_is_active} = active_subscription_clause()

    if @subscriptions_enabled do
      from s in Subscription, as: ^identifier,
        join: d in assoc(s, :data_space),
        where: ^(dynamic([s, _], s.checkout_id == ^checkout_id and ^subscription_is_active)),
        select: d
    else
      from d in DataSpace,
        where: d.handle == ^checkout_id
    end
  end

  def subscription_plan_query(product_id) do
    from s in Subscription,
      where: s.subscription_plan_id == ^product_id,
      preload: [:data_space]
  end
end
