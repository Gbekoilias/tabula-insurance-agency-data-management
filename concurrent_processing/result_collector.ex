defmodule ResultCollector do
  use Agent
  require Logger

  def start_link(_opts \\ []) do
    Agent.start_link(
      fn -> %{results: [], metadata: %{started_at: System.system_time(:second)}} end,
      name: __MODULE__
    )
  end

  def add_result(simulation_id, result) do
    Agent.update(__MODULE__, fn state ->
      new_results = [Map.put(result, :simulation_id, simulation_id) | state.results]
      %{state | results: new_results}
    end)
  end

  def get_aggregated_results do
    Agent.get(__MODULE__, fn state ->
      results = state.results
      %{
        summary: summarize_results(results),
        metadata: get_metadata(state.metadata),
        raw_results: results
      }
    end)
  end

  defp summarize_results(results) do
    results
    |> Enum.group_by(& &1.simulation_id)
    |> Enum.map(fn {id, sims} ->
      %{
        simulation_id: id,
        avg_output: Enum.average(Enum.map(sims, & &1.output)),
        min_output: Enum.min_by(sims, & &1.output).output,
        max_output: Enum.max_by(sims, & &1.output).output,
        total_iterations: length(sims)
      }
    end)
  end

  defp get_metadata(metadata) do
    Map.put(metadata, :duration_seconds,
      System.system_time(:second) - metadata.started_at)
  end

  def reset do
    Agent.update(__MODULE__, fn _state ->
      %{results: [], metadata: %{started_at: System.system_time(:second)}}
    end)
  end
end
