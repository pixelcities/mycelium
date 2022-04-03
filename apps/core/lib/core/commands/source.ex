defmodule Core.Commands.CreateSource do
  use Commanded.Command,
    id: :string,
    workspace: :string,
    type: :string,
    uri: :string,
    schema: :map,
    is_published: {:boolean, default: false}

  alias Core.Types.Schema

  defp validate_schema(changeset) do
    schema = changeset
    |> fetch_field!(:schema)
    |> Schema.new()

    Enum.reduce(schema.errors, changeset, fn {err, {message, additional}}, changeset -> add_error(changeset, err, message, additional) end)
  end

  def validate_uri_namespace(changeset, data_space, workspace) do
    changeset
    |> validate_change(:uri, fn :uri, uri ->
      if !String.starts_with?(uri, "s3://pxc-collection-store/#{data_space}/#{workspace}/") do
        [uri: "invalid namespace"]
      else
        []
      end
    end)
  end

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id])
    |> validate_schema()
  end
end

defmodule Core.Commands.UpdateSource do
  use Commanded.Command,
    id: :string,
    workspace: :string,
    type: :string,
    uri: :string,
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
    |> validate_schema()
  end
end
