defmodule DataStore.Data do
  @moduledoc """
  """

  @config Application.get_env(:data_store, DataStore.Data)
  @bucket @config[:bucket]

  alias ExAws.S3

  def validate_uri(uri) do
    case Regex.named_captures(~r/^s3:\/\/(?<bucket>[a-z0-9-]+)\/(?<ds>[a-z0-9_]{1,255})\/(?<workspace>[a-z0-9-]{1,255})\/(?<type>[a-z]+)\/(?<dataset>[a-z0-9-]{36})(?:\/v(?<version>[0-9]{1,10}))?$/, uri) do
      nil -> {:error, "invalid_uri"}
      %{
        "bucket" => @bucket,
        "ds" => ds,
        "workspace" => workspace,
        "type" => type,
        "dataset" => dataset,
        "version" => version
      } -> {:ok, ds, workspace, type, dataset, version}
      _ -> {:error, "unauthorized"}
    end
  end

  @doc """
  Truncate dataset

  If the bucket is versioned, this will only mark the objects for deletion.
  """
  def truncate_dataset(uri) do
    case validate_uri(uri) do
      {:ok, ds, workspace, type, dataset, _version} ->
        S3.list_objects_v2(@bucket, prefix: "#{ds}/#{workspace}/#{type}/#{dataset}/")
          |> ExAws.stream!()
          |> Enum.reduce_while(:ok, fn obj, _acc ->
            case S3.delete_object(@bucket, obj.key) |> ExAws.request() do
              {:ok, _} -> {:cont, :ok}
              {:error, error} -> {:halt, {:error, error}}
            end
          end)

      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Delete parent dataset

  Same as truncate_dataset/1. When there are no more leaves, the path seizes to exist as well.
  """
  def delete_dataset(uri), do: truncate_dataset(uri)
end
