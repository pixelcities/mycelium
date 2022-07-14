defmodule Landlord.Mailer do
  @moduledoc """
  View development emails using `Swoosh.Adapters.Local.Storage.Memory`
  """

  use Swoosh.Mailer, otp_app: :landlord
end
