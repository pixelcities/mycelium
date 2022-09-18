defmodule DataStore.DataTokens do
  @moduledoc """
  Generate temporary credentials for data URIs

  """

  @config Application.get_env(:data_store, DataStore.DataTokens)
  @bucket @config[:bucket]
  @role_arn @config[:role_arn]
  @restrict_source_ip @config[:restrict_source_ip]

  alias MetaStore
  alias Landlord.Tenants

  @doc """
  Generate access credentials for the given URI

  The credentials are valid for 15 minutes, and grant read or write s3 operations on the given
  subpath within the collection bucket.
  """
  def generate_data_tokens(uri, mode, user, ip) do
    with :ok <- validate_mode(mode),
         :ok <- validate_path(user, uri, mode)
    do
      path = String.trim(Enum.at(String.split(uri, @bucket), 1), "/")

      policy = case mode do
        "read" -> read_policy(path)
        "write" -> write_policy(path)
      end

      query = ExAws.STS.assume_role(@role_arn, user.id,
        [
          {:duration, 900},
          {:policy, harden_policy(policy, ip)}
        ]
      )
      {:ok, %{body: body}} = ExAws.request(query)

      {:ok, %{
        "access_key" => body.access_key_id,
        "secret_key" => body.secret_access_key,
        "session_token" => body.session_token
      }}
    else
      err -> err
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
    with {:ok, ds, _, _} <- parse_uri(uri, :read),
         :ok <- validate_data_space(ds, user)
    do
      sources = MetaStore.get_sources_by_user(user, tenant: ds)
      collections = MetaStore.get_collections_by_user(user, tenant: ds)

      uris = Enum.map(sources, fn s -> s.uri end) ++ Enum.map(collections, fn c -> c.uri end)

      if uri in uris do
        :ok
      else
        {:error, "unauthorized"}
      end
    else
      err -> err
    end
  end

  # TODO: validate dataset was requested beforehand
  defp validate_path(user, uri, "write") do
    with {:ok, ds, workspace, _, _} <- parse_uri(uri, :write),
         :ok <- validate_data_space(ds, user),
         :ok <- validate_workspace(workspace, user)
    do
      :ok
    else
      err -> err
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
    case Regex.named_captures(~r/^s3:\/\/(?<bucket>[a-z0-9-]+)\/(?<ds>[a-z0-9_]+)\/(?<workspace>[a-z0-9-]+)\/(?<dataset>[a-z0-9-]+)$/, uri) do
      nil -> {:error, "invalid_uri"}
      %{
        "bucket" => @bucket,
        "ds" => ds,
        "workspace" => workspace,
        "dataset" => dataset
      } -> {:ok, ds, workspace, dataset}
      _ -> {:error, "unauthorized"}
    end
  end

  defp parse_uri(uri, :write) do
    case Regex.named_captures(~r/^s3:\/\/(?<bucket>[a-z0-9-]+)\/(?<ds>[a-z0-9_]+)\/(?<workspace>[a-z0-9-]+)\/(?<dataset>[a-z0-9-]+)\/(?<fragment>[a-z0-9-]+).parquet$/, uri) do
      nil -> {:error, "invalid_uri"}
      %{
        "bucket" => @bucket,
        "ds" => ds,
        "workspace" => workspace,
        "dataset" => dataset,
        "fragment" => fragment
      } -> {:ok, ds, workspace, dataset, fragment}
      _ -> {:error, "unauthorized"}
    end
  end

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
