defmodule Core.Commands.CreateSource do
  use Commanded.Command,
    id: :string,
    workspace: :string,
    type: :string,
    uri: {{:array, :string}, []},
    schema: :map,
    is_published: {:boolean, default: false}

  alias Core.Types.Schema

  defp validate_schema(changeset) do
    schema = changeset
    |> fetch_field!(:schema)
    |> Schema.new()

    Enum.reduce(schema.errors, changeset, fn {err, {message, additional}}, changeset -> add_error(changeset, err, message, additional) end)
  end

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
    changeset
    |> validate_change(:uri, fn :uri, [uri, _tag] ->
      if uri in uris, do: [uri: "invalid namespace"], else: []
    end)
  end

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id])
    |> validate_length(:uri, is: 2)
    |> validate_schema()
    |> validate_integrity()
  end
end

defmodule Core.Commands.UpdateSource do
  use Core.Utils.EnrichableCommand,
    id: :string,
    workspace: :string,
    type: :string,
    uri: {{:array, :string}, []},
    schema: :map,
    is_published: {:boolean, default: false}

  alias Core.Types.Schema

  defp validate_schema(changeset) do
    schema = changeset
    |> fetch_field!(:schema)
    |> Schema.new()

    Enum.reduce(schema.errors, changeset, fn {err, {message, additional}}, changeset -> add_error(changeset, err, message, additional) end)
  end

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace])
    |> validate_length(:uri, is: 2)
    |> validate_schema()
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

