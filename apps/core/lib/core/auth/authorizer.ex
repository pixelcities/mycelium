defmodule Core.Auth.Authorizer do

  @doc """
  Placeholder for more advanced authorization rules
  """
  def authorized?(user, shares) do
    Enum.any?(shares, fn share ->
      if Map.get(share, "type") == "public" || Map.get(share, "type") == "internal" do
        true

      else
        !!user && user.email == Map.get(share, "principal")
      end
    end)
  end

  def is_public?(shares) do
    Enum.any?(shares, fn share ->
      Map.get(share, "type") == "public"
    end)
  end

end
