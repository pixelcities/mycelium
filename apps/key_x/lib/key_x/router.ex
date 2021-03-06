defmodule KeyX.Router do

  use Commanded.Commands.Router

  alias Core.Commands.ShareSecret
  alias KeyX.Aggregates.Secret

  identify(Secret, by: :receiver, prefix: "secrets-")

  dispatch([ShareSecret],
    to: Secret
  )

end
