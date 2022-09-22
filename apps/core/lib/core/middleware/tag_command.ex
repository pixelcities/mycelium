defmodule Core.Middleware.TagCommand do
  @behaviour Commanded.Middleware

  alias Commanded.Middleware.Pipeline
  import Commanded.Middleware.Pipeline

  @doc """
  Tag each command with metadata

  TODO: Use correlation id
  """
  def before_dispatch(%Pipeline{} = pipeline) do
    %Pipeline{command: command, metadata: _metadata} = pipeline

    pipeline
    |> assign_metadata("ds_id", :ds1)
  end

  def after_dispatch(%Pipeline{} = pipeline) do
    pipeline
  end

  def after_failure(%Pipeline{} = pipeline) do
    pipeline
  end
end
