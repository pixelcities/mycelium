defmodule DataStore.DataTokens do
  @moduledoc """
  Generate temporary credentials for data URIs

  """

  require Logger

  @config Application.get_env(:data_store, DataStore.Data)
  @bucket @config[:bucket]
  @restrict_source_ip @config[:restrict_source_ip]

  alias MetaStore
  alias Landlord.Tenants
  alias DataStore.Data
  alias Core.Integrity

  @doc """
  Generate access credentials for the given URI

  The credentials are valid for 15 minutes, and grant read or write s3 operations on the given
  subpath within the collection bucket.
  """
  def generate_data_tokens(uri, tag, mode, user, ip) do
    with :ok <- validate_mode(mode),
         {:ok, valid_uri} <- validate_path(user, uri, mode),
         :ok <- Integrity.verify(valid_uri, tag)
    do
      path = String.trim(Enum.at(String.split(uri, @bucket), 1), "/")

      policy = case mode do
        "read" -> read_policy(path)
        "write" -> write_policy(path)
      end

      role_arn = Application.get_env(:data_store, DataStore.Data)[:role_arn]

      query = ExAws.STS.assume_role(role_arn, user.id,
        [
          {:duration, 900},
          {:policy, harden_policy(policy, ip)}
        ]
      )

      case ExAws.request(query) do
        {:ok, %{body: body}} ->
          {:ok, %{
            "access_key" => body.access_key_id,
            "secret_key" => body.secret_access_key,
            "session_token" => body.session_token
          }}
        {:error, error} ->
          Logger.error(Exception.format(:error, error))
          Logger.debug(policy)

          {:error, :invalid_policy}
      end
    else
      err ->
        Logger.error(Exception.format(:error, err))
        err
    end
  end

  defp read_policy(path) do
    %{
      "Version" => "2012-10-17",
      "Statement" => [
        %{
          "Effect" => "Allow",
          "Action" => [
            "s3:GetObject"
          ],
          "Resource" => "arn:aws:s3:::" <> @bucket <> "/" <> path <> "/*"
        },
        %{
          "Effect" => "Allow",
          "Action" => [
            "s3:ListBucket"
          ],
          "Resource" => "arn:aws:s3:::" <> @bucket,
          "Condition" => %{
            "StringLike" => %{
              "s3:prefix" => [
                path <> "/"
              ]
            }
          }
        }
      ]
    }
  end

  defp write_policy(path) do
    %{
      "Version" => "2012-10-17",
      "Statement" => [
        %{
          "Effect" => "Allow",
          "Action" => [
            "s3:CreateMultipartUpload",
            "s3:AbortMultipartUpload",
            "s3:PutObject"
          ],
          "Resource" => "arn:aws:s3:::" <> @bucket <> "/" <> path,
          "Condition" => %{
            "StringLikeIfExists" => %{
              "s3:x-amz-storage-class" => [
                "STANDARD"
              ]
            }
          }
        }
      ]
    }
  end

  defp validate_mode(mode) when mode in ["read", "write"], do: :ok
  defp validate_mode(_mode), do: {:error, "invalid_mode"}

  defp validate_path(user, uri, "read") do
    with {:ok, ds, _, _, _, _} <- parse_uri(uri, :read),
         :ok <- validate_data_space(ds, user),
         :ok <- validate_ownership(uri, user, ds)
    do
      {:ok, uri}
    else
      err -> err
    end
  end

  defp validate_path(user, uri, "write") do
    with {:ok, ds, workspace, type, dataset, version, _} <- parse_uri(uri, :write),
         :ok <- validate_data_space(ds, user),
         :ok <- validate_workspace(workspace, user)
    do
      normalized_uri = rebuild_uri(ds, workspace, type, dataset, version)
      uris = MetaStore.get_all_uris(tenant: ds)

      # Validate the caller has access to this URI
      if normalized_uri in uris do
        case validate_ownership(normalized_uri, user, ds) do
          :ok -> {:ok, normalized_uri}
          err -> err
        end

      # If there is no such path, this is the creator
      else
        {:ok, normalized_uri}
      end
    else
      err -> err
    end
  end

  defp validate_ownership(uri, user, ds) do
    # TODO: offload to db instead of returning all uris
    sources = MetaStore.get_sources_by_user(user, tenant: ds)
    collections = MetaStore.get_collections_by_user(user, tenant: ds)

    # Strip version information
    uris = Enum.map(sources, fn s -> Regex.replace(~r/\/v[0-9]{1,10}$/, s.uri, "") end) ++ Enum.map(collections, fn c -> Regex.replace(~r/\/v[0-9]{1,10}$/, c.uri, "") end)

    if Regex.replace(~r/\/v[0-9]{1,10}$/, uri, "") in uris do
      :ok
    else
      {:error, "unauthorized"}
    end
  end

  defp validate_workspace(workspace, _user) when workspace == "default", do: :ok
  defp validate_workspace(_workspace, _user), do: {:error, "invalid_workspace"}

  defp validate_data_space(ds, user) do
    data_spaces = Enum.map(Tenants.get_data_spaces_by_user(user), fn ds -> ds.handle end)

    if ds in data_spaces do
      :ok
    else
      {:error, "invalid_data_space"}
    end
  end

  defp parse_uri(uri, :read) do
    Data.validate_uri(uri)
  end

  defp parse_uri(uri, :write) do
    case Regex.named_captures(~r/^s3:\/\/(?<bucket>[a-z0-9-]+)\/(?<ds>[a-z0-9_]{1,255})\/(?<workspace>[a-z0-9-]{1,255})\/(?<type>[a-z]+)\/(?<dataset>[a-z0-9-]{36})(?:\/v(?<version>[0-9]{1,10}))?\/(?<fragment>[a-z0-9-]{36}).parquet$/, uri) do
      nil -> {:error, "invalid_uri"}
      %{
        "bucket" => @bucket,
        "ds" => ds,
        "workspace" => workspace,
        "type" => type,
        "dataset" => dataset,
        "version" => version,
        "fragment" => fragment
      } -> {:ok, ds, workspace, type, dataset, version, fragment}
      _ -> {:error, "unauthorized"}
    end
  end

  defp rebuild_uri(ds, workspace, type, dataset, ""), do: "s3://#{@bucket}/#{ds}/#{workspace}/#{type}/#{dataset}"
  defp rebuild_uri(ds, workspace, type, dataset, version), do: "s3://#{@bucket}/#{ds}/#{workspace}/#{type}/#{dataset}/v#{version}"

  defp harden_policy(policy, ip) do
    if @restrict_source_ip do
      Map.put(policy, "Statement",
        Enum.map(Map.get(policy, "Statement", []), fn statement ->
          condition = Map.get(statement, "Condition", %{})
          Map.put(statement, "Condition", Map.put(condition, "IpAddress", %{"aws:SourceIp" => ip}))
        end)
      )
    else
      policy
    end
  end

end
