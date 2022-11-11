defmodule Core.Utils.Web do
  @config Application.get_env(:core, Core)[:from]

  @doc """
  Returns a URL with the host pointing to the front-end
  """
  def get_external_host() do
    %URI{
      scheme: @config[:scheme],
      host: @config[:host],
      port: @config[:port]
    }
  end
end
