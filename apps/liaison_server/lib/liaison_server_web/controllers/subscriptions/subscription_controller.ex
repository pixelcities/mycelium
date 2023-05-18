defmodule LiaisonServerWeb.Subscriptions.SubscriptionController do
  use LiaisonServerWeb, :controller

  alias Landlord.Tenants
  alias Landlord.Tenants.SubscriptionApi

  require Logger

  def get_subscription(conn, %{"handle" => handle}) do
    user = conn.assigns.current_user

    with {:ok, data_space} <- Tenants.get_data_space_by_user_and_handle(user, handle, unsafe: true),
         true <- Tenants.is_owner?(data_space, user),
         subscription <- Tenants.get_subscription(data_space)
    do
      json(conn, subscription && %{
        subscription_id: subscription.subscription_id,
        status: subscription.status,
        cancel_url: subscription.cancel_url,
        update_url: subscription.update_url,
        valid_to: subscription.valid_to,
        plan_name: SubscriptionApi.get_plan_name(subscription.subscription_plan_id)
      })

    else
      err ->
        Logger.error(Exception.format(:error, err))
        conn |> put_status(404) |> json(%{"status" => "not found"})
    end
  end

  def get_subscription_available(conn, %{"plan" => plan}) do
    user = conn.assigns.current_user

    case SubscriptionApi.get_plan_id(plan) do
      nil -> conn |> put_status(400) |> json(%{"status" => "bad request"})
      product_id ->
        is_available? = Tenants.subscription_available?(user, product_id)

        json(conn, %{
          product_id: product_id,
          is_available: is_available?
        })
    end
  end

  def change_subscription_plan(conn, %{"subscription_id" => subscription_id, "plan" => plan}) do
    user = conn.assigns.current_user

    case SubscriptionApi.get_plan_id(plan) do
      nil -> conn |> put_status(400) |> json(%{"status" => "bad request"})
      product_id ->
        with subscription <- Tenants.get_subscription(subscription_id),
             true <- Tenants.is_owner?(subscription.data_space, user),
             true <- Tenants.subscription_available?(user, product_id),
             true <- Tenants.subscription_downgrade_available?(subscription.data_space, product_id),
             {:ok, :done} <- SubscriptionApi.change_plan(subscription.subscription_id, product_id)
        do
          json(conn, "")
        else
          err ->
            Logger.error(Exception.format(:error, err))
            conn |> put_status(500) |> json(%{"status" => "error"})
        end
    end
  end
end
