defmodule Core.Commands.CreateCollection do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    type: :string,
    uri: :string,
    schema: :map,
    targets: {{:array, :binary_id}, default: []},
    position: {{:array, :float}, default: [0.0, 0.0]},
    color: {:string, default: "#000000"},
    is_ready: {:boolean, default: false}

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :type, :uri, :schema])
    |> validate_inclusion(:type, ["source", "collection"])
    |> validate_component()
    |> validate_schema()
  end
end

defmodule Core.Commands.UpdateCollection do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    type: :string,
    uri: :string,
    schema: :map,
    targets: {{:array, :binary_id}, default: []},
    position: {{:array, :float}, default: [0.0, 0.0]},
    color: {:string, default: "#000000"},
    is_ready: {:boolean, default: false}

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :type, :uri, :schema])
    |> validate_inclusion(:type, ["source", "collection"])
    |> validate_component()
    |> validate_schema()
  end
end

defmodule Core.Commands.AddCollectionTarget do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    target: :binary_id

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :target])
  end
end

defmodule Core.Commands.SetCollectionPosition do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    position: {{:array, :float}, default: [0.0, 0.0]}

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :position])
    |> validate_position()
  end
end

defmodule Core.Commands.CreateTransformer do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    type: :string,
    targets: {{:array, :binary_id}, default: []},
    position: {{:array, :float}, default: [0.0, 0.0]},
    color: {:string, default: "#000000"},
    is_ready: {:boolean, default: false},
    collections: {{:array, :binary_id}, default: []},
    transformers: {{:array, :binary_id}, default: []},
    wal: :map

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :type])
    |> validate_inclusion(:type, ["merge", "function", "custom"])
    |> validate_component()
    |> validate_wal([:allow_nil])
  end
end

defmodule Core.Commands.UpdateTransformer do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    type: :string,
    targets: {{:array, :binary_id}, default: []},
    position: {{:array, :float}, default: [0.0, 0.0]},
    color: {:string, default: "#000000"},
    is_ready: {:boolean, default: false},
    collections: {{:array, :binary_id}, default: []},
    transformers: {{:array, :binary_id}, default: []},
    wal: :map

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :type])
    |> validate_inclusion(:type, ["merge", "function", "custom"])
    |> validate_component()
    |> validate_wal([:allow_nil])
  end
end

defmodule Core.Commands.SetTransformerPosition do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    position: {{:array, :float}, default: [0.0, 0.0]}

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :position])
    |> validate_position()
  end
end

defmodule Core.Commands.AddTransformerTarget do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    target: :binary_id

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :target])
  end
end

defmodule Core.Commands.AddTransformerInput do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    collection: :binary_id,
    transformer: :binary_id

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace])
    |> validate_one_of([:collection, :transformer])
  end
end

defmodule Core.Commands.UpdateTransformerWAL do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    wal: :map

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :wal])
    |> validate_wal()
  end
end

