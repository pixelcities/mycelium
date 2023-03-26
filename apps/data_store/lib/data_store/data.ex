defmodule DataStore.Data do
  @moduledoc """
  """

  @config Application.get_env(:data_store, DataStore.Data)
  @bucket @config[:bucket]

  alias ExAws.S3

  def validate_uri(uri) do
    case Regex.named_captures(~r/^s3:\/\/(?<bucket>[a-z0-9-]+)\/(?<ds>[a-z0-9_]{1,255})\/(?<workspace>[a-z0-9-]{1,255})\/(?<type>[a-z]+)\/(?<dataset>[a-z0-9-]{36})$/, uri) do
      nil -> {:error, "invalid_uri"}
      %{
        "bucket" => @bucket,
        "ds" => ds,
        "workspace" => workspace,
        "type" => _type,
        "dataset" => dataset
      } -> {:ok, ds, workspace, dataset}
      _ -> {:error, "unauthorized"}
    end
  end

  @doc """
  Truncate dataset

  If the bucket is versioned, this will only mark the objects for deletion.
  """
  def truncate_dataset(uri) do
    case validate_uri(uri) do
      {:ok, ds, workspace, dataset} ->
        S3.list_objects_v2(@bucket, prefix: "#{ds}/#{workspace}/#{dataset}/")
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

  Most work is done by truncate_dataset/1, this fn will just cleanup the parent
  path to conclude.
  """
  def delete_dataset(uri) do
    with :ok <- truncate_dataset(uri) do
      case S3.delete_object(@bucket, uri) |> ExAws.request() do
        {:ok, _} -> :ok
        {:error, error} -> {:error, error}
      end
    else
      err -> err
    end
  end
end
