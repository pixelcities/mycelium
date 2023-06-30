defmodule Core.Commands.CreateCollection do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    type: :string,
    uri: {{:array, :string}, []},
    schema: Core.Types.Schema,
    targets: {{:array, :binary_id}, default: []},
    position: {{:array, :float}, default: [0.0, 0.0]},
    color: {:string, default: "#000000"},
    is_ready: {:boolean, default: false}

  def validate_source(changeset, nil), do: add_error(changeset, :type, "Cannot validate source")
  def validate_source(changeset, source) do
    changeset
    |> validate_inclusion(:type, ["source"])
    |> validate_change(:uri, fn :uri, [uri, _tag] ->
      if uri != source.uri, do: [uri: "invalid URI"], else: []
    end)
  end

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :type, :uri, :schema])
    |> validate_inclusion(:type, ["source", "collection"])
    |> validate_component()
  end
end

defmodule Core.Commands.UpdateCollection do
  import Core.Types.Component

  use Core.Utils.EnrichableCommand,
    id: :binary_id,
    workspace: :string,
    type: :string,
    uri: {{:array, :string}, []},
    schema: Core.Types.Schema,
    targets: {{:array, :binary_id}, default: []},
    position: {{:array, :float}, default: [0.0, 0.0]},
    color: {:string, default: "#000000"},
    is_ready: {:boolean, default: false}

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :type, :uri, :schema])
    |> validate_inclusion(:type, ["source", "collection"])
    |> validate_component()
  end
end

defmodule Core.Commands.UpdateCollectionSchema do
  import Core.Types.Component

  use Core.Utils.EnrichableCommand,
    id: :binary_id,
    workspace: :string,
    schema: Core.Types.Schema

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :schema])
  end
end

defmodule Core.Commands.AddCollectionTarget do
  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    target: :binary_id

  def validate_transformer_target(changeset, transformer) do
    changeset
    |> validate_change(:target, fn :target, _target ->
      max_inputs = if transformer.type == "merge", do: 2, else: 1

      if length(transformer.collections) < max_inputs, do: [], else: [target: "too many inputs"]
    end)
  end

  def validate_widget_target(changeset, widget) do
    changeset
    |> validate_change(:target, fn :target, _target ->
      unless widget.collection, do: [], else: [target: "already has input"]
    end)
  end

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :target])
  end
end

defmodule Core.Commands.RemoveCollectionTarget do
  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    target: :binary_id

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :target])
  end
end

defmodule Core.Commands.SetCollectionColor do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    color: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :color])
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

defmodule Core.Commands.SetCollectionIsReady do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    is_ready: {:boolean, default: false}

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :is_ready])
  end
end

defmodule Core.Commands.DeleteCollection do
  import Core.Types.Component

  use Core.Utils.EnrichableCommand,
    id: :binary_id,
    workspace: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace])
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
    wal: :map,
    error: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :type])
    |> validate_inclusion(:type, ["merge", "function", "filter", "aggregate", "custom", "privatise", "attribute", "mpc"])
    |> validate_component()
    |> validate_wal([allow_nil: true])
  end
end

defmodule Core.Commands.UpdateTransformer do
  import Core.Types.Component

  use Core.Utils.EnrichableCommand,
    id: :binary_id,
    workspace: :string,
    type: :string,
    targets: {{:array, :binary_id}, default: []},
    position: {{:array, :float}, default: [0.0, 0.0]},
    color: {:string, default: "#000000"},
    is_ready: {:boolean, default: false},
    collections: {{:array, :binary_id}, default: []},
    transformers: {{:array, :binary_id}, default: []},
    wal: :map,
    error: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :type])
    |> validate_inclusion(:type, ["merge", "function", "filter", "aggregate", "custom", "privatise", "attribute", "mpc"])
    |> validate_component()
    |> validate_wal([allow_nil: true])
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

defmodule Core.Commands.RemoveTransformerTarget do
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

  use Core.Utils.EnrichableCommand,
    id: :binary_id,
    workspace: :string,
    wal: :map

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :wal])
    |> validate_wal()
  end
end

defmodule Core.Commands.SetTransformerIsReady do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    is_ready: {:boolean, default: false}

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :is_ready])
  end
end

defmodule Core.Commands.SetTransformerError do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    is_error: :boolean,
    error: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :is_error])
  end
end

defmodule Core.Commands.ApproveTransformer do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    nr_parties: :integer,
    signatures: {{:array, :string}, default: []}

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :signatures])
  end
end

defmodule Core.Commands.DeleteTransformer do
  use Commanded.Command,
    id: :binary_id,
    workspace: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace])
  end
end

defmodule Core.Commands.CreateWidget do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    type: :string,
    position: {{:array, :float}, default: [0.0, 0.0]},
    color: {:string, default: "#000000"},
    is_ready: {:boolean, default: false},
    collection: :binary_id,
    settings: {:map, default: %{}},
    access: {{:array, :map}, default: [%{type: "internal"}]},
    content: :string,
    height: :integer,
    is_published: {:boolean, default: false}

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :type])
    |> validate_inclusion(:type, ["chart", "map"])
    |> validate_format(:color, ~r/^#[0-9a-fA-F]{6}$/)
    |> validate_position()
    |> validate_shares(:access)
  end
end

defmodule Core.Commands.UpdateWidget do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    type: :string,
    position: {{:array, :float}, default: [0.0, 0.0]},
    color: {:string, default: "#000000"},
    is_ready: {:boolean, default: false},
    collection: :binary_id,
    settings: {:map, default: %{}},
    access: {{:array, :map}, default: [%{type: "internal"}]},
    content: :string,
    height: :integer,
    is_published: {:boolean, default: false}

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :type])
    |> validate_inclusion(:type, ["chart", "map"])
    |> validate_format(:color, ~r/^#[0-9a-fA-F]{6}$/)
    |> validate_position()
    |> validate_shares(:access)
  end
end

defmodule Core.Commands.SetWidgetPosition do
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

defmodule Core.Commands.SetWidgetIsReady do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    is_ready: {:boolean, default: false}

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :is_ready])
  end
end

defmodule Core.Commands.AddWidgetInput do
  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    collection: :binary_id

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :collection])
  end
end

defmodule Core.Commands.PutWidgetSetting do
  use Core.Utils.EnrichableCommand,
    id: :binary_id,
    workspace: :string,
    key: :string,
    value: {:string, default: ""}

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :key])
  end
end

defmodule Core.Commands.PublishWidget do
  import Core.Types.Component

  use Commanded.Command,
    id: :binary_id,
    workspace: :string,
    access: {{:array, :map}, default: [%{type: "internal"}]},
    content: :string,
    height: :integer,
    is_published: {:boolean, default: false}

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace, :access, :content, :height, :is_published])
    |> validate_shares(:access)
  end
end

defmodule Core.Commands.DeleteWidget do
  use Core.Utils.EnrichableCommand,
    id: :binary_id,
    workspace: :string

  def handle_validate(changeset) do
    changeset
    |> validate_required([:id, :workspace])
  end
end

