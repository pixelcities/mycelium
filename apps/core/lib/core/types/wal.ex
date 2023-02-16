defmodule Core.Types.WAL do
  @moduledoc """

  ## Basic example statements

  Normal cases mostly consist of transactions that reference identifiers and
  values. While transactions cannot really be validated, their usage of identifier
  and value references are checked.

      iex> Core.Types.WAL.new(%{
      ...>   "identifiers" => %{
      ...>     "1" => %{"id" => "table", "type" => "table"},
      ...>     "2" => %{"id" => "col1", "type" => "column"}
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


  ## Identifier instructions

  Identifiers may reference either tables or columns. Because in most operations schemas
  are assumed to be immutable, identifiers can optionally include actions thate can mutate
  the schema. Other actions are also possible, but rare.

  The two mutations that are commonly used are: "add" and "drop". Adding or altering a column
  requires a reference to the linked concept.

      iex> Core.Types.WAL.new(%{
      ...>   "identifiers" => %{
      ...>     "1" => %{"id" => "table", "type" => "table"},
      ...>     "2" => %{"id" => "col1", "type" => "column", "action" => "drop"},
      ...>     "3" => %{"id" => "col2", "type" => "column", "action" => "add", "params" => ["concept"]}
      ...>   },
      ...>   "values" => %{},
      ...>   "transactions" => [],
      ...>   "artifacts" => []
      ...> }).valid?
      true

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
    |> validate_identifiers()
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
      if not Regex.match?(~r/^[0-9\[\],|]+$/, artifact) do
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

  defp validate_identifiers(changeset) do
    identifiers = get_field(changeset, :identifiers)

    Enum.reduce(identifiers, changeset, fn {_i, %{"id" => _id, "type" => type} = identifier}, acc ->
      action = Map.get(identifier, "action")
      params = Map.get(identifier, "params", [])

      unless Enum.all?(Map.keys(identifier), fn k -> k in ["id", "type", "action", "params"] end) do
        add_error(acc, :identifiers, "Unexpected key in identifier")
      else
        unless type == "table" || type == "column" do
          add_error(acc, :identifiers, "Type must be either \"table\" or \"column\"")
        else
          unless action == nil || action == "add" || action == "drop" || action == "alter" do
            add_error(acc, :identifiers, "Action must be one of: [\"add\",\"drop\",\"alter\"]")
          else
            unless action == nil || action == "drop" || ((action == "add" || action == "alter") && length(params) == 1) do
              add_error(acc, :identifiers, "A required parameter is missing from an \"add\" or \"alter\" action")
            else
              acc
            end
          end
        end
      end
    end)
  end
end

