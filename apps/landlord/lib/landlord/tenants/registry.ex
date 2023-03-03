defmodule Landlord.Registry do

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)

    Registry.start_link(name: name, keys: :duplicate)
  end

  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :name, __MODULE__),
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end

  def dispatch(application, opts \\ []) when is_atom(application) do
    mode = Keyword.get(opts, :mode, "start")

    Registry.dispatch(__MODULE__, mode, fn entries ->
      entries
      |> Enum.sort_by(fn {_pid, {weight, _module, _function}} -> weight end)
      |> Enum.each(fn {_pid, {_weight, module, function}} ->
        apply(module, function, [application])
      end)
    end)
  end

end
