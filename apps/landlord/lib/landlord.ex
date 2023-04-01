defmodule Landlord do
  @moduledoc """
  Documentation for `Landlord`.
  """

  @app Landlord.Application.get_app()

  alias Core.Commands.{
    CreateUser,
    UpdateUser,
    DeleteUser,
    InviteUser,
    AcceptInvite,
    ConfirmInvite,
    CancelInvite,
    SendUserNotification,
    MarkNotificationRead
  }


  def create_user(attrs, %{"user_id" => _user_id, "ds_id" => ds_id} = metadata), do: dispatch(CreateUser.new(attrs), ds_id, metadata)

  def update_user(attrs, %{"user_id" => _user_id, "ds_id" => ds_id} = metadata), do: dispatch(UpdateUser.new(attrs), ds_id, metadata)

  def delete_user(attrs, %{"user_id" => _user_id, "ds_id" => ds_id} = metadata), do: dispatch(DeleteUser.new(attrs), ds_id, metadata)

  def notify_user(attrs, %{"ds_id" => ds_id} = metadata), do: dispatch(SendUserNotification.new(attrs), ds_id, metadata)

  def mark_notification_read(attrs, %{"ds_id" => ds_id} = metadata) do
    case dispatch(MarkNotificationRead.new(attrs), ds_id, metadata) do
      {:ok, :done} -> {:ok, :done}
      {:error, :notification_does_not_exist} -> {:ok, :done}
      err -> err
    end
  end

  def invite_user(attrs, %{"user_id" => _user_id, "ds_id" => ds_id} = metadata), do: dispatch(InviteUser.new(attrs), ds_id, metadata)

  def accept_invite(attrs, %{"user_id" => _user_id, "ds_id" => ds_id} = metadata), do: dispatch(AcceptInvite.new(attrs), ds_id, metadata)

  def confirm_invite(attrs, %{"user_id" => _user_id, "ds_id" => ds_id} = metadata), do: dispatch(ConfirmInvite.new(attrs), ds_id, metadata)

  def cancel_invite(attrs, %{"user_id" => _user_id, "ds_id" => ds_id} = metadata), do: dispatch(CancelInvite.new(attrs), ds_id, metadata)

  defp dispatch(command, ds_id, metadata) do
    with :ok <- @app.validate_and_dispatch(command, consistency: :eventual, application: Module.concat(@app, ds_id), metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end

end
