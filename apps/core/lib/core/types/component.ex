defmodule Core.Types.Component do
  import Ecto.Changeset

  alias Core.Types.{Share, WAL}

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

  def validate_shares(changeset, field \\ :shares) do
    shares = fetch_field!(changeset, field)

    Enum.reduce(shares, changeset, fn attrs, changeset ->
      share = Share.new(attrs)

      Enum.reduce(share.errors, changeset, fn {err, {message, additional}}, changeset -> add_error(changeset, err, message, additional) end)
    end)
  end

  def validate_wal(changeset, opts \\ []) do
    allow_nil = Keyword.get(opts, :allow_nil, false)

    field = fetch_field!(changeset, :wal)
    if allow_nil and field == nil do
      changeset
    else
      wal = WAL.new(field)

      Enum.reduce(wal.errors, changeset, fn {err, {message, additional}}, changeset -> add_error(changeset, err, message, additional) end)
    end
  end

end

