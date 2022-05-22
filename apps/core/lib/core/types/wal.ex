defmodule Core.Types.WAL do
  @moduledoc """

  ## Example statements

      iex> Core.Types.WAL.new(%{
      ...>   "identifiers" => %{
      ...>     "1" => "table",
      ...>     "2" => "col1"
      ...>   },
      ...>   "values" => %{
      ...>     "1" => "1"
      ...>   },
      ...>   "transactions" => [
      ...>     "UPDATE %1$I SET %2$I = $1;"
      ...>   ],
      ...>   "artifacts" => [
      ...>     "[1,2,3]"
      ...>   ]
      ...> }).valid?
      true

      iex> Core.Types.WAL.new(%{
      ...>   "identifiers" => %{},
      ...>   "values" => %{},
      ...>   "transactions" => [
      ...>     "SELECT $1"
      ...>   ],
      ...>   "artifacts" => [
      ...>     "[1,2,3]"
      ...>   ]
      ...> }).errors
      [{:transactions, {"Non-existent parameter at positions: [\\"$1\\"]", []}}]

  """
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  schema "schema" do
    field :identifiers, :map
    field :values, :map
    field :transactions, {:array, :string}
    field :artifacts, {:array, :string}
  end

  def changeset(wal, attrs) do
    wal
    |> cast(attrs, [:identifiers, :values, :transactions, :artifacts])
  end

  def new(attrs) do
    changeset(%__MODULE__{}, attrs)
    |> validate_required([:identifiers, :values, :transactions, :artifacts])
    |> validate_statements()
    |> validate_artifacts()
    |> validate_length()
  end

  defp validate_statements(changeset) do
    transactions = get_field(changeset, :transactions)

    Enum.reduce(transactions, changeset, fn transaction, acc ->
      errors = case Regex.scan(~r/(?:%([0-9]+)\$I)|(?>(?<!\$)\$(?!\$)([0-9]+))/, transaction) do
        nil -> []
        positions -> Enum.reduce(positions, [], fn position, err ->
          field = if String.starts_with?(hd(position), "$"), do: :values, else: :identifiers

          if Map.has_key?(get_field(changeset, field), Enum.at(position, -1)), do: err, else: [hd(position) | err]
        end)
      end

      if Enum.any?(errors) do
        add_error(acc, :transactions, "Non-existent parameter at positions: #{inspect errors}")
      else
        acc
      end
    end)
  end

  defp validate_artifacts(changeset) do
    artifacts = get_field(changeset, :artifacts)

    Enum.reduce(artifacts, changeset, fn artifact, acc ->
      # Basic check
      if not Regex.match?(~r/^[0-9\[\],]+$/, artifact) do
        add_error(acc, :artifacts, "Invalid character in artifact")
      else
        acc
      end
    end)
  end

  defp validate_length(changeset) do
    transactions = get_field(changeset, :transactions)
    artifacts = get_field(changeset, :artifacts)

    if length(transactions) != length(artifacts) do
      add_error(changeset, :artifacts, "Number of artifacts does not equal number of statements")
    else
      changeset
    end
  end

end

