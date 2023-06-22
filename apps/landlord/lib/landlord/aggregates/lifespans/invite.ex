defmodule Landlord.Aggregates.InviteLifespan do
  @behaviour Commanded.Aggregates.AggregateLifespan

  alias Core.Events.{
    InviteConfirmed,
    InviteCancelled
  }

  def after_event(%InviteConfirmed{}), do: :stop
  def after_event(%InviteCancelled{}), do: :hibernate

  def after_event(_event), do: :infinity
  def after_command(_command), do: :infinity
  def after_error(_error), do: :stop
end

