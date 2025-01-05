defmodule SimulationWorker do
  use GenServer
  require Logger

  defmodule State do
    defstruct [:params, :status, :results, started_at: nil]
  end

  def start_link(params) do
    GenServer.start_link(__MODULE__, params)
  end

  def get_status(pid), do: GenServer.call(pid, :status)
  def get_results(pid), do: GenServer.call(pid, :results)

  @impl true
  def init(params) do
    send(self(), :run_simulation)
    {:ok, %State{params: params, status: :initialized}}
  end

  @impl true
  def handle_call(:status, _from, state), do: {:reply, state.status, state}
  def handle_call(:results, _from, state), do: {:reply, state.results, state}

  @impl true
  def handle_info(:run_simulation, state) do
    Task.async(fn -> run_simulation(state.params) end)
    {:noreply, %{state | status: :running, started_at: System.system_time(:second)}}
  end

  def handle_info({ref, results}, %{status: :running} = state) do
    Process.demonitor(ref, [:flush])
    {:noreply, %{state | status: :completed, results: results}}
  end

  defp run_simulation(params) do
    results = params
    |> generate_scenarios()
    |> Enum.map(&run_scenario/1)
    |> aggregate_results()

    {:ok, results}
  end

  defp generate_scenarios(params) do
    Enum.map(1..params.iterations, fn i ->
      Map.put(params, :seed, i)
    end)
  end

  defp run_scenario(scenario) do
    :rand.seed(:exs1024, {scenario.seed, scenario.seed, scenario.seed})
    # Simulation logic here
    %{
      iteration: scenario.seed,
      output: :rand.uniform() * scenario.multiplier
    }
  end

  defp aggregate_results(results) do
    %{
      iterations: length(results),
      avg_output: Enum.average(Enum.map(results, & &1.output)),
      results: results
    }
  end
end
