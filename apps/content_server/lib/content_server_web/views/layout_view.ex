defmodule ContentServerWeb.LayoutView do
  use ContentServerWeb, :view

  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}
end
