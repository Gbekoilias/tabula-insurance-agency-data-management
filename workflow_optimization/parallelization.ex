defmodule ParallelProcessing do
  use Flow

  # Define a function to simulate a task
  def simulate_task(item) do
    IO.puts("Processing #{item}")
    :timer.sleep(1000)  # Simulate a time-consuming task
    IO.puts("Processed #{item}")
    String.upcase(item)
  end

  # Function to run parallel tasks and measure execution time
  def run_parallel_tasks(tasks) do
    start_time = System.monotonic_time()

    # Create a flow from the list of tasks and process them in parallel
    results =
      tasks
      |> Flow.from_enumerable()
      |> Flow.map(&simulate_task/1)
      |> Enum.to_list()  # Trigger the flow execution

    execution_time = System.monotonic_time() - start_time
    {results, execution_time}
  end
end

# Main function to execute the parallel processing
defmodule Main do
  def run do
    tasks = ["one", "two", "three", "four", "five"]

    {results, execution_time} = ParallelProcessing.run_parallel_tasks(tasks)

    IO.puts("Results: #{inspect(results)}")
    IO.puts("Total Execution Time: #{execution_time / 1_000_000} seconds")
  end
end

# Run the main function
Main.run()
