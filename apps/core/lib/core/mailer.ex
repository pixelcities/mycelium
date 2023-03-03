defmodule Core.Mailer do
  @moduledoc """
  View development emails using `Swoosh.Adapters.Local.Storage.Memory`
  """

  use Swoosh.Mailer, otp_app: :core
end

defmodule Core.Email do
  import Swoosh.Email

  def deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"PixelCities", "no-reply@pixelcities.io"})
      |> subject(subject)
      |> text_body(render_body(body))

    with {:ok, _metadata} <- Core.Mailer.deliver(email) do
      {:ok, email}
    end
  end

  defp render_body(body) do
    """
    <html>
    <body>
    <section style="background-color: white; margin: 0 auto; width: 768px;">
    <div class="container" style="1.5rem 1rem 1.5rem 1rem">
    <div style="margin-left: -0.5rem; padding-top: 2rem">
    <img style="width: 16rem" src="https://pixelcities.io/pxc-web-logo-b.png">
    </div>

    <div style="display: inline-block;">
    <div style="margin-top: 1rem; margin-bottom: -1rem; border-top: 1px; border-top-color: #363636; border-top-style: solid;"></div>

    #{body}
    </div>
    </div>
    </section>
    </body>
    </html>
    """
  end
end
