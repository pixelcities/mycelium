defmodule Maestro.Aggregates.MPC do
  defstruct id: nil,
            nr_parties: nil,
            submitted: 0,
            values: %{}

  alias Maestro.Aggregates.MPC
  alias Core.Commands.{CreateMPC, ShareMPCPartial, ShareMPCResult}
  alias Core.Events.{MPCCreated, MPCPartialShared, MPCResultShared}

  @threshold 1

  def execute(%MPC{id: nil}, %CreateMPC{} = command) do
    MPCCreated.new(command, date: NaiveDateTime.utc_now())
  end

  def execute(%MPC{nr_parties: nr_parties, submitted: submitted, values: values}, %ShareMPCPartial{} = command) do
    if submitted == nr_parties - 1 do
      {partitions, results} =
        Map.to_list(merge_values(values, command.partitions, command.values))
        |> Enum.filter(fn {_, partials } ->
          nr_values = Enum.count(partials, fn x -> x != "" end)
          # Verify that enough parties have submitted values
          nr_values >= 3 and nr_values >= nr_parties - @threshold
        end)
        |> Enum.map(fn {partition_key, partials} ->
          # Values are stored as strings up until now because JS does not like to deal with potentially
          # huge numbers. Time to parse these to integers and sum everything.
          result =
            partials
            |> Enum.map(fn x ->
              {int, _} = Integer.parse(x)
              int
            end)
            |> Enum.sum()
            |> Integer.to_string()

            {partition_key, result}
        end)
        |> Enum.unzip()

      MPCResultShared.new(%{
        id: command.id,
        partitions: partitions,
        values: results,
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
      submitted: mpc.submitted + 1,
      values: merge_values(mpc.values, event.partitions, event.values)
    }
  end

  def apply(%MPC{} = mpc, %MPCResultShared{} = event) do
    %MPC{mpc |
      id: event.id,
      submitted: 0,
      values: %{}
    }
  end

  defp merge_values(old_map, partitions, values) do
    Enum.zip(partitions, values)
    |> Enum.reduce(old_map, fn {k, v}, acc ->
      {_, result} =
        Map.get_and_update(acc, k, fn value ->
          {value, Enum.concat(value || [], [v])}
        end)

      result
    end)
  end
end
