defmodule Landlord.Tenants.SubscriptionApi do
  @moduledoc false

  require Logger

  @subscriptions_enabled Application.compile_env(:landlord, Landlord.Tenants.SubscriptionApi)[:enabled]

  @plans %{
    "free" => %{
      product_id: "50825",
      max_users: 3,
      max_plans: 1
    },
    "standard" => %{
      product_id: "50826",
      max_users: :unlimited,
      max_plans: :unlimited
    }
  }
  @product_ids Map.values(@plans) |> Enum.map(fn x -> x[:product_id] end)

  def get_plan_id(name), do: @plans[String.downcase(name)][:product_id]

  def get_user_limit(id), do:
    Map.values(@plans) |> Enum.find_value(fn x -> if x[:product_id] == id, do: x[:max_users] end)

  def get_plan_limit(id), do:
    Map.values(@plans) |> Enum.find_value(fn x -> if x[:product_id] == id, do: x[:max_plans] end)


  def within_user_limit?(id, new_quantity), do: within_limit?(get_user_limit(id), new_quantity)
  def within_plan_limit?(id, new_quantity), do: within_limit?(get_plan_limit(id), new_quantity)

  def generate_redirect(product_id, email, handle) when
    product_id in @product_ids and not is_nil(email) and not is_nil(handle)
  do
    generate_pay_link(%{
      product_id: product_id,
      customer_email: email,
      passthrough: handle
    })
  end

  def change_seats(subscription_id, new_quantity) when is_number(new_quantity) do
    update_subscription(subscription_id, %{
      quantity: new_quantity,
      bill_immediately: false
    })
  end

  def change_plan(subscription_id, product_id) when product_id in @product_ids do
    update_subscription(subscription_id, %{
      plan_id: product_id,
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

  defp within_limit?(limit, value) do
    if @subscriptions_enabled do
      case limit do
        nil -> false
        :unlimited -> true
        max -> value <= max
      end
    else
      true
    end
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
            _ -> {:error, nil}
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

      case Req.post(config[:basepath] <> "/api/2.0/subscription/users_cancel", json: data) do
        {:ok, response} ->
          case response.body do
            %{"success" => true} -> {:ok, :cancelled}
            %{"error" => %{"message" => error}} -> {:error, error}
            _ -> {:error, nil}
          end
        {:error, e} ->
          Logger.error("Error during cancel subscription request: #{inspect(e)}")

          {:error, :request_error}
      end
    else
      {:ok, :subscriptions_disabled}
    end
  end

  defp generate_pay_link(params) do
    return_url = URI.merge(Core.Utils.Web.get_external_host(), "/checkout")

    if @subscriptions_enabled do
      config = config()
      data =
        Map.merge(params, %{
          vendor_id: config[:vendor_id],
          vendor_auth_code: config[:vendor_auth_code],
          discountable: 0,
          quantity_variable: 0,
          quantity: 1,
          return_url: URI.to_string(URI.merge(return_url, "?checkout={checkout_hash}"))
        })

      case Req.post(config[:basepath] <> "/api/2.0/product/generate_pay_link", json: data) do
        {:ok, response} ->
          case response.body do
            %{"success" => true, "response" => %{"url" => url}} -> {:ok, url}
            %{"error" => %{"message" => error}} -> {:error, error}
            _ -> {:error, nil}
          end
        {:error, e} ->
          Logger.error("Error during generate pay link request: #{inspect(e)}")

          {:error, :request_error}
      end
    else
      {:ok, URI.to_string(URI.merge(return_url, "?checkout=#{params[:passthrough]}"))}
    end
  end
end
