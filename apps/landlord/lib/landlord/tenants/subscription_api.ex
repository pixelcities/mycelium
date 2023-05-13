defmodule Landlord.Tenants.SubscriptionApi do
  @moduledoc false

  require Logger

  @subscriptions_enabled Application.compile_env(:landlord, Landlord.Tenants.SubscriptionApi)[:enabled]

  def change_seats(subscription_id, new_quantity) do
    update_subscription(subscription_id, %{
      quantity: new_quantity,
      bill_immediately: false
    })
  end

  def change_plan(subscription_id, plan_id) do
    update_subscription(subscription_id, %{
      plan_id: plan_id,
      bill_immediately: true
    })
  end

  def pause(subscription_id, state) when is_boolean(state) do
    update_subscription(subscription_id, %{pause: state})
  end

  def cancel(subscription_id) do
    cancel_subscription(subscription_id)
  end

  defp config() do
    Application.get_env(:landlord, Landlord.Tenants.SubscriptionApi)
  end

  defp update_subscription(subscription_id, params) do
    if @subscriptions_enabled do
      config = config()
      data =
        Map.merge(params, %{
          vendor_id: config[:vendor_id],
          vendor_auth_code: config[:vendor_auth_code],
          subscription_id: subscription_id,
          prorate: true
        })

      case Req.post(config[:basepath] <> "/api/2.0/subscription/users/update", json: data) do
        {:ok, response} ->
          case response.body do
            %{"success" => true} -> {:ok, :done}
            %{"error" => %{"message" => error}} -> {:error, error}
          end
        {:error, e} ->
          Logger.error("Error during update subscription request: #{inspect(e)}")

          {:error, :request_error}
      end
    else
      {:ok, :subscriptions_disabled}
    end
  end

  defp cancel_subscription(subscription_id) do
    if @subscriptions_enabled do
      config = config()
      data = %{
        vendor_id: config[:vendor_id],
        vendor_auth_code: config[:vendor_auth_code],
        subscription_id: subscription_id
      }

      case Req.post!(config[:basepath] <> "/api/2.0/subscription/users_cancel", json: data) do
        {:ok, response} ->
          case response.body do
            %{"success" => true} -> {:ok, :cancelled}
            %{"error" => %{"message" => error}} -> {:error, error}
          end
        {:error, e} ->
          Logger.error("Error during cancel subscription request: #{inspect(e)}")

          {:error, :request_error}
      end
    else
      {:ok, :subscriptions_disabled}
    end
  end
end
