defmodule WorkflowManager do
  use Supervisor

  # Define the workflow steps
  @workflow_steps [
    :initialize,
    :process_data,
    :validate_data,
    :finalize
  ]

  # Start the supervisor
  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  # Initialize the supervisor and start the workflow processes
  def init(:ok) do
    children = for step <- @workflow_steps do
      {WorkflowStep, step}
    end

    # Supervise the workflow steps
    Supervisor.init(children, strategy: :one_for_one)
  end

  # Start the workflow process
  def start_workflow do
    IO.puts("Starting workflow...")
    Enum.each(@workflow_steps, fn step ->
      case start_step(step) do
        :ok -> IO.puts("#{step} completed successfully.")
        {:error, reason} -> IO.puts("Error in #{step}: #{reason}")
      end
    end)
  end

  # Start a specific workflow step
  defp start_step(step) do
    case Supervisor.start_child(__MODULE__, {WorkflowStep, step}) do
      {:ok, _pid} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

end

defmodule WorkflowStep do
  use GenServer

  # Start the GenServer for each workflow step
  def start_link(step) do
    GenServer.start_link(__MODULE__, step, name: via_tuple(step))
  end

  # Define the GenServer state initialization
  def init(step) do
    {:ok, %{step: step, current_status: :pending}}
  end

  # Handle the execution of each workflow step
  def handle_call(:execute, _from, state) do
    new_status = execute_step(state.step)
    {:reply, new_status, %{state | current_status: new_status}}
  end

  # Execute the specific workflow step logic
  defp execute_step(:initialize) do
    IO.puts("Initializing...")
    :completed
  end

  defp execute_step(:process_data) do
    IO.puts("Processing data...")
    :completed
  end

  defp execute_step(:validate_data) do
    IO.puts("Validating data...")
    :completed
  end

  defp execute_step(:finalize) do
    IO.puts("Finalizing...")
    :completed
  end

  # Helper function to create a unique name for each step process in the supervision tree
  defp via_tuple(step) do
    {:via, Registry, {WorkflowRegistry, step}}
  end

end

# To run the workflow manager:
{:ok, _} = WorkflowManager.start_link([])
WorkflowManager.start_workflow()
