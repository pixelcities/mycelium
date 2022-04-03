defmodule DataStore.DataTokens do
  @moduledoc """
  Generate temporary credentials for data URIs

  """

  @bucket "pxc-collection-store"
  @role_arn "arn:aws:iam::120183265440:role/mycelium-s3-collection-manager"

  @doc """
  Generate access credentials for the given URI

  The credentials are valid for 30 minutes, and grant read/write s3 operations on the given
  subpath within the collection bucket.

  TODO: validate uri / user
  """
  def generate_data_tokens(uri, user_id) do
    path = String.trim(Enum.at(String.split(uri, @bucket), 1), "/")

    policy = %{
      "Version" => "2012-10-17",
      "Statement" => [
        %{
          "Effect" => "Allow",
          "Action" => [
            "s3:*"
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

    query = ExAws.STS.assume_role(@role_arn, user_id,
      [
        {:duration, 1800},
        {:policy, policy}
      ]
    )
    {:ok, %{body: body}} = ExAws.request(query)

    %{
      "access_key" => body.access_key_id,
      "secret_key" => body.secret_access_key,
      "session_token" => body.session_token
    }
  end

end
