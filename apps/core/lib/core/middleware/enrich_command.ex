defmodule Core.Middleware.EnrichCommand do
  @behaviour Commanded.Middleware

  alias Commanded.Middleware.Pipeline
  alias Core.Middleware.CommandEnrichment

  @doc """
  Enrich the command via the opt-in command enrichment protocol.
  """
  def before_dispatch(%Pipeline{command: command, metadata: metadata} = pipeline) do
    case CommandEnrichment.enrich(command, metadata) do
      {:ok, command} ->
        %Pipeline{pipeline | command: command}

      {:error, _error} = reply ->
        pipeline
        |> Pipeline.respond(reply)
        |> Pipeline.halt()
    end
  end

  def after_dispatch(pipeline), do: pipeline

  def after_failure(pipeline), do: pipeline
end

