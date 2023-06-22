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
            height: nil,
            is_published: false,
            date: nil

  alias MetaStore.Aggregates.Widget
  alias Core.Commands.{CreateWidget, UpdateWidget, SetWidgetPosition, SetWidgetIsReady, AddWidgetInput, PutWidgetSetting, PublishWidget, DeleteWidget}
  alias Core.Events.{WidgetCreated, WidgetUpdated, WidgetPositionSet, WidgetIsReadySet, WidgetInputAdded, WidgetSettingPut, WidgetPublished, WidgetDeleted}


  def execute(%Widget{id: nil}, %CreateWidget{} = widget) do
    WidgetCreated.new(widget,
      is_ready: true,
      date: NaiveDateTime.utc_now()
    )
  end

  def execute(%Widget{settings: settings} = widget, %UpdateWidget{} = update)
    when widget.workspace == update.workspace
  do
    # Don't allow changing settings through this command
    WidgetUpdated.new(update,
      settings: settings,
      date: NaiveDateTime.utc_now())
  end

  def execute(%Widget{} = _widget, %SetWidgetPosition{} = position) do
    WidgetPositionSet.new(position, date: NaiveDateTime.utc_now())
  end

  def execute(%Widget{} = _widget, %SetWidgetIsReady{} = command) do
    WidgetIsReadySet.new(command, date: NaiveDateTime.utc_now())
  end

  def execute(%Widget{} = widget, %AddWidgetInput{} = command) do
    unless widget.collection do
      WidgetInputAdded.new(command, date: NaiveDateTime.utc_now())
    else
      {:error, :widget_already_has_input}
    end
  end

  def execute(%Widget{} = _widget, %PutWidgetSetting{__metadata__: %{user_id: user_id, shares: shares}} = command) do
    if valid_setting?(command.key, user_id, shares) do
      WidgetSettingPut.new(command, date: NaiveDateTime.utc_now())
    else
      {:error, :unauthorized}
    end
  end

  def execute(%Widget{} = _widget, %PublishWidget{} = command) do
    WidgetPublished.new(command, date: NaiveDateTime.utc_now())
  end

  def execute(%Widget{} = _widget, %DeleteWidget{__metadata__: %{user_id: user_id, is_admin: is_admin, shares: shares}} = command) do
    if is_admin || authorized?(user_id, shares) do
      WidgetDeleted.new(command, date: NaiveDateTime.utc_now())
    else
      {:error, :unauthorized}
    end
  end

  defp authorized?(user_id, shares) do
    Enum.any?(shares, fn share ->
      share.principal == user_id
    end)
  end

  defp valid_setting?(key, user_id, shares) do
    if String.contains?(String.downcase(key, :ascii), "column"), do: authorized?(user_id, shares), else: true
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

  def apply(%Widget{} = widget, %WidgetIsReadySet{} = event) do
    %Widget{widget |
      is_ready: event.is_ready,
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
      height: event.height,
      is_published: event.is_published,
      date: event.date
    }
  end

  def apply(%Widget{} = widget, %WidgetDeleted{} = _event), do: widget

end
