defmodule KeyX.Protocol.Agent do
  use Rustler, otp_app: :key_x, crate: "key_x_protocol_agent"


  # Native

  def encrypt_once(_user_id, _user_bundle, _message), do: :erlang.nif_error(:nif_not_loaded)
end

