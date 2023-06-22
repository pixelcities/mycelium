defmodule Maestro.Aggregates.MPC do
  defstruct id: nil,
            nr_parties: nil,
            values: []

  alias Maestro.Aggregates.MPC
  alias Core.Commands.{CreateMPC, ShareMPCPartial, ShareMPCResult}
  alias Core.Events.{MPCCreated, MPCPartialShared, MPCResultShared}

  def execute(%MPC{id: nil}, %CreateMPC{} = command) do
    MPCCreated.new(command, date: NaiveDateTime.utc_now())
  end

  def execute(%MPC{nr_parties: nr_parties, values: values}, %ShareMPCPartial{} = command) do
    if length(values) == nr_parties - 1 do
      result = Enum.sum(values ++ [command.value])

      # TODO: Also emit the partial
      MPCResultShared.new(%{
        id: command.id,
        value: result,
        date: NaiveDateTime.utc_now()
      })
    else
      MPCPartialShared.new(command, date: NaiveDateTime.utc_now())
    end
  end

  def execute(%MPC{}, %ShareMPCResult{}), do: {:error, :not_implemented}

  # State mutators

  def apply(%MPC{} = mpc, %MPCCreated{} = event) do
    %MPC{mpc |
      id: event.id,
      nr_parties: event.nr_parties
    }
  end

  def apply(%MPC{} = mpc, %MPCPartialShared{} = event) do
    %MPC{mpc |
      id: event.id,
      values: Enum.concat(mpc.values, [event.value])
    }
  end

  def apply(%MPC{} = mpc, %MPCResultShared{} = event) do
    %MPC{mpc |
      id: event.id,
      values: []
    }
  end
end
