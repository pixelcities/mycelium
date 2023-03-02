defmodule Core.Middleware.TagCommand do
  @behaviour Commanded.Middleware

  alias Commanded.Middleware.Pipeline
  import Commanded.Middleware.Pipeline

  @doc """
  Tag each command with metadata
  """
  def before_dispatch(%Pipeline{} = pipeline) do
    %Pipeline{metadata: metadata, correlation_id: correlation_id} = pipeline

    # Record the event, so that future events may lookup the metadata
    Core.Timeline.record(correlation_id, metadata)

    unless Map.has_key?(metadata, "ds_id") do
      # If an event (mostly coming from managers) is lacking the ds_id, we
      # try looking up past events for that id or fallback to parsing it from
      # the module name.
      ds_id = case Core.Timeline.lookup(correlation_id) do
        {:ok, meta} -> Map.get(meta, "ds_id")
        {:error, _} -> extract_ds_from_application(pipeline)
      end

      pipeline
      |> assign_metadata("ds_id", ds_id)
    else
      pipeline
    end
  end

  def after_dispatch(%Pipeline{} = pipeline) do
    pipeline
  end

  def after_failure(%Pipeline{} = pipeline) do
    pipeline
  end

  # Hacky fallback, extract the ds_id from the commanded application name
  defp extract_ds_from_application(%{application: application} = _pipeline) do
    String.to_atom(Enum.at(Module.split(application), -1))
  end
end
