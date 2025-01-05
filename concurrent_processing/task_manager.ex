defmodule TaskManager do
  use GenServer
  require Logger

  # Client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__] ++ opts)
  end

  def submit_task(task_func) do
    GenServer.call(__MODULE__, {:submit, task_func})
  end

  def get_result(task_id) do
    GenServer.call(__MODULE__, {:get_result, task_id})
  end

  def list_tasks do
    GenServer.call(__MODULE__, :list_tasks)
  end

  # Server Callbacks
  @impl true
  def init(:ok) do
    {:ok, %{tasks: %{}, results: %{}}}
  end

  @impl true
  def handle_call({:submit, task_func}, _from, state) do
    task_id = UUID.uuid4()
    task = Task.async(fn ->
      try do
        {:ok, task_func.()}
      rescue
        e -> {:error, Exception.message(e)}
      end
    end)

    new_state = put_in(state.tasks[task_id], task)
    {:reply, {:ok, task_id}, new_state}
  end

  @impl true
  def handle_call({:get_result, task_id}, _from, state) do
    case Map.get(state.tasks, task_id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      task ->
        case Task.yield(task, 5000) do
          {:ok, result} ->
            new_state = state
              |> update_in([:tasks], &Map.delete(&1, task_id))
              |> put_in([:results, task_id], result)
            {:reply, result, new_state}
          nil ->
            {:reply, {:error, :timeout}, state}
        end
    end
  end

  @impl true
  def handle_call(:list_tasks, _from, state) do
    tasks = Map.keys(state.tasks)
    {:reply, tasks, state}
  end

  @impl true
  def handle_info({ref, result}, state) do
    case find_task_id(state.tasks, ref) do
      nil -> {:noreply, state}
      task_id ->
        new_state = state
          |> update_in([:tasks], &Map.delete(&1, task_id))
          |> put_in([:results, task_id], result)
        {:noreply, new_state}
    end
  end

  defp find_task_id(tasks, ref) do
    Enum.find_value(tasks, fn {id, task} ->
      if task.ref == ref, do: id
    end)
  end
end
