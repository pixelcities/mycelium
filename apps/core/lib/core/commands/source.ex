defmodule Core.Commands.CreateSource do
  use Commanded.Command,
    id: :string,
    workspace: :string,
    type: :string,
    uri: {{:array, :string}, []},
    schema: Core.Types.Schema,
    is_published: {:boolean, default: false}

  defp validate_integrity(changeset) do
    [uri, tag] = fetch_field!(changeset, :uri)

    unless Core.Integrity.is_valid?(uri, tag) do
      add_error(changeset, :uri, "Invalid URI")
    else
      changeset
    end
  end

  def validate_uri_namespace(changeset, data_space, workspace) do
    changeset
    |> validate_change(:uri, fn :uri, [uri, _tag] ->
      if !String.starts_with?(uri, "s3://pxc-collection-store/#{data_space}/#{workspace}/source/") do
        [uri: "invalid namespace"]
      else
        []
      end
    end)
  end

  def validate_uri_uniqueness(changeset, uris) do
    # Strip version information
    normalized_uris = Enum.map(uris, fn uri -> Regex.replace(~r/\/v[0-9]{1,10}$/, uri, "") end)

    changeset
    |> validate_change(:uri, fn :uri, [uri, _tag] ->
      if Regex.replace(~r/\/v[0-9]{1,10}$/, uri, "") in normalized_uris, do: [uri: "invalid uri"], else: []
    end)
  end

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id])
    |> validate_length(:uri, is: 2)
    |> validate_integrity()
  end
end

defmodule Core.Commands.UpdateSource do
  use Core.Utils.EnrichableCommand,
    id: :string,
    workspace: :string,
    type: :string,
    uri: {{:array, :string}, []},
    schema: Core.Types.Schema,
    is_published: {:boolean, default: false}

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace])
    |> validate_length(:uri, is: 2)
  end
end

defmodule Core.Commands.UpdateSourceSchema do
  use Core.Utils.EnrichableCommand,
    id: :string,
    workspace: :string,
    schema: Core.Types.Schema

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :schema])
  end
end

defmodule Core.Commands.UpdateSourceURI do
  use Core.Utils.EnrichableCommand,
    id: :string,
    workspace: :string,
    uri: {{:array, :string}, []}

  defp validate_integrity(changeset) do
    [uri, tag] = fetch_field!(changeset, :uri)

    unless Core.Integrity.is_valid?(uri, tag) do
      add_error(changeset, :uri, "Invalid URI")
    else
      changeset
    end
  end

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :uri])
    |> validate_length(:uri, is: 2)
    |> validate_integrity()
  end
end

defmodule Core.Commands.DeleteSource do
  use Core.Utils.EnrichableCommand,
    id: :string,
    workspace: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace])
  end
end

