defmodule MetaStore.Aggregates.WidgetLifespan do
  @behaviour Commanded.Aggregates.AggregateLifespan

  alias Core.Events.WidgetDeleted

  def after_event(%WidgetDeleted{}), do: :stop
  def after_event(_event), do: :infinity
  def after_command(_command), do: :infinity
  def after_error(_error), do: :stop
end

defmodule MetaStore.Aggregates.Widget do
  defstruct id: nil,
            workspace: nil,
            type: nil,
            position: [],
            color: "#000000",
            is_ready: false,
            collection: nil,
            settings: %{},
            access: "internal",
            content: nil,
            is_published: false,
            date: nil

  alias MetaStore.Aggregates.Widget
  alias Core.Commands.{CreateWidget, UpdateWidget, SetWidgetPosition, AddWidgetInput, PutWidgetSetting, PublishWidget, DeleteWidget}
  alias Core.Events.{WidgetCreated, WidgetUpdated, WidgetPositionSet, WidgetInputAdded, WidgetSettingPut, WidgetPublished, WidgetDeleted}


  def execute(%Widget{id: nil}, %CreateWidget{} = widget) do
    WidgetCreated.new(widget, date: NaiveDateTime.utc_now())
  end

  def execute(%Widget{} = widget, %UpdateWidget{} = update)
    when widget.workspace == update.workspace
  do
    WidgetUpdated.new(update, date: NaiveDateTime.utc_now())
  end

  def execute(%Widget{} = _widget, %SetWidgetPosition{} = position) do
    WidgetPositionSet.new(position, date: NaiveDateTime.utc_now())
  end

  def execute(%Widget{} = widget, %AddWidgetInput{} = command) do
    unless widget.collection do
      WidgetInputAdded.new(command, date: NaiveDateTime.utc_now())
    else
      {:error, :widget_already_has_input}
    end
  end

  def execute(%Widget{} = _widget, %PutWidgetSetting{} = command) do
    WidgetSettingPut.new(command, date: NaiveDateTime.utc_now())
  end

  def execute(%Widget{} = _widget, %PublishWidget{} = command) do
    WidgetPublished.new(command, date: NaiveDateTime.utc_now())
  end

  def execute(%Widget{} = _widget, %DeleteWidget{} = command) do
    WidgetDeleted.new(command, date: NaiveDateTime.utc_now())
  end


  # State mutators

  def apply(%Widget{} = widget, %WidgetCreated{} = created) do
    %Widget{widget |
      id: created.id,
      workspace: created.workspace,
      type: created.type,
      position: created.position,
      color: created.color,
      is_ready: created.is_ready,
      collection: created.collection,
      date: created.date
    }
  end

  def apply(%Widget{} = widget, %WidgetUpdated{} = updated) do
    %Widget{widget |
      is_ready: updated.is_ready,
      date: updated.date
    }
  end

  def apply(%Widget{} = widget, %WidgetPositionSet{} = event) do
    %Widget{widget |
      position: event.position,
      date: event.date
    }
  end

  def apply(%Widget{} = widget, %WidgetInputAdded{} = event) do
    %Widget{widget |
      collection: event.collection,
      date: event.date
    }
  end

  def apply(%Widget{} = widget, %WidgetSettingPut{} = event) do
    %Widget{widget |
      settings: Map.put(widget.settings, event.key, event.value),
      date: event.date
    }
  end

  def apply(%Widget{} = widget, %WidgetPublished{} = event) do
    %Widget{widget |
      access: event.access,
      content: event.content,
      is_published: event.is_published,
      date: event.date
    }
  end

  def apply(%Widget{} = widget, %WidgetDeleted{} = event), do: widget

end
