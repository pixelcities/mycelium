defmodule Core.Auth.Authorizer do

  @doc """
  Placeholder for more advanced authorization rules
  """
  def authorized?(%{} = user, shares, is_ds_member?), do: authorized?(user.id, shares, is_ds_member?)
  def authorized?(user_id, shares, is_ds_member?) do
    Enum.any?(shares, fn share ->
      case Map.get(share, "type") do
        "public" -> true
        "internal" -> is_ds_member?
        _ -> !!user_id && user_id == Map.get(share, "principal")
      end
    end)
  end

  def is_public?(shares) do
    Enum.any?(shares, fn share ->
      Map.get(share, "type") == "public"
    end)
  end

end
