defmodule Landlord.Accounts.UserNotifier do
  alias Landlord.Email

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    Email.deliver(user.email, "Confirmation instructions", """
    <p style="font-size: 1rem; color: #363636;"><br /> Welcome to DataGarden! </p>

    <p style="font-size: 1rem; color: #363636; padding-bottom: 1rem;"> Please confirm your email address by clicking on the following link: </p>

    <a href="#{url}" style="font-size: 1.25rem; background-color: #3457a6; color: white; cursor: pointer; justify-content: center; padding: calc(.5em - 2px) 1em; text-align: center; white-space: nowrap; align-items: center; border: 2px solid transparent; border-radius: 4px; box-shadow: none; display: inline-flex; height: 2rem; line-height: 1.5; position: relative; vertical-align: top; font-family: sans-serif; margin: 0; font-weight: 400; box-sizing: inherit; user-select: none; text-decoration: none;">
      Confirm email
    </a>

    <p style="font-size: 1rem; color: #363636; padding-top: 1rem;">  If you didn't create an account with us, please ignore this. </p>

    <p style="font-size: 1rem; color: #363636; padding-top: 0.25rem;">PixelCities </p>
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    Email.deliver(user.email, "Update email instructions", """
    <p style="font-size: 1rem; color: #363636;"><br /> Hi #{user.email}, </p>

    <p style="font-size: 1rem; color: #363636; padding-bottom: 1rem;"> You can change your email by clicking the link below: </p>

    <a href="#{url}" style="font-size: 1.25rem; background-color: #3457a6; color: white; cursor: pointer; justify-content: center; padding: calc(.5em - 2px) 1em; text-align: center; white-space: nowrap; align-items: center; border: 2px solid transparent; border-radius: 4px; box-shadow: none; display: inline-flex; height: 2rem; line-height: 1.5; position: relative; vertical-align: top; font-family: sans-serif; margin: 0; font-weight: 400; box-sizing: inherit; user-select: none; text-decoration: none;">
      Change email
    </a>

    <p style="font-size: 1rem; color: #363636; padding-top: 1rem;">  If you didn't request this change, please ignore this. </p>

    <p style="font-size: 1rem; color: #363636; padding-top: 0.25rem;">PixelCities </p>
    """)
  end

  @doc """
  Deliver invitation to data space
  """
  def deliver_invitation(email, inviter_email, url) do
    Email.deliver(email, "You've been invited to join a data space", """
    <p style="font-size: 1rem; color: #363636;"><br /> Hi #{email}, </p>

    <p style="font-size: 1rem; color: #363636; padding-bottom: 1rem;"> You have been invited to join "#{inviter_email}"s data space! </p>

    <a href="#{url}" style="font-size: 1.25rem; background-color: #3457a6; color: white; cursor: pointer; justify-content: center; padding: calc(.5em - 2px) 1em; text-align: center; white-space: nowrap; align-items: center; border: 2px solid transparent; border-radius: 4px; box-shadow: none; display: inline-flex; height: 2rem; line-height: 1.5; position: relative; vertical-align: top; font-family: sans-serif; margin: 0; font-weight: 400; box-sizing: inherit; user-select: none; text-decoration: none;">
      Accept invitation
    </a>

    <p style="font-size: 1rem; color: #363636; padding-top: 1rem;"> If you do not wish to join, you can ignore this email. </p>

    <p style="font-size: 1rem; color: #363636; padding-top: 0.25rem;">PixelCities </p>
    """)
  end
end
