defimpl Core.Middleware.CommandEnrichment, for: Core.Commands.UpdateSource do

  alias Core.Commands.UpdateSource

  @doc """
  The aggregates needs to know which user is attempting to execute this command
  """
  def enrich(%UpdateSource{} = command, %{"user_id" => user_id} = metadata) do
    {:ok, %{command |
      __metadata__: %{
        user_id: user_id
      }
    }}

  end
end
