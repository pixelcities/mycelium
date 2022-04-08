defmodule Core.Types.Component do
  import Ecto.Changeset

  alias Core.Types.{Schema, WAL}

  defp validate_targets(changeset) do
    changeset
    |> validate_change(:targets, fn :targets, targets ->
      errors = Enum.filter(targets, fn target ->
        !String.match?(target, ~r/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)
      end)

      if length(errors) > 0 do
        [targets: "not a valid uuid"]
      else
        []
      end
    end)
  end

  def validate_position(changeset) do
    changeset
    |> validate_change(:position, fn :position, position ->
      if !length(position) == 2 do
        [position: "position needs both an x and y coordinate"]
      else
        []
      end
    end)
  end

  def validate_component(changeset) do
    changeset
    |> validate_format(:color, ~r/^#[0-9a-fA-F]{6}$/)
    |> validate_targets()
    |> validate_position()
  end

  def validate_one_of(changeset, fields) do
    if Enum.any?(fields, fn field -> get_field(changeset, field) != nil end) do
      changeset
    else
      add_error(changeset, hd(fields), "missing one of these fields: #{inspect fields}")
    end
  end

  def validate_schema(changeset) do
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

  def validate_wal(changeset) do
    wal = changeset
    |> fetch_field!(:wal)
    |> WAL.new()

    Enum.reduce(wal.errors, changeset, fn {err, {message, additional}}, changeset -> add_error(changeset, err, message, additional) end)
  end

end

