defmodule Disco.Orchestrator do
  @moduledoc """
  Orchestrates several aggregates together.
  """

  use GenServer

  ## Client API

  def start_link(modules) when is_list(modules) do
    GenServer.start_link(__MODULE__, %{modules: modules}, name: __MODULE__)
  end

  @doc """
  Returns a list of available commands.
  """
  @spec commands() :: [:atom]
  def commands do
    GenServer.call(__MODULE__, :commands)
  end

  @doc """
  Returns a list of available queries.
  """
  @spec queries() :: [:atom]
  def queries do
    GenServer.call(__MODULE__, :queries)
  end

  @doc """
  Executes a command if available. It runs sync by default, use `async: true` option to
  run async.
  """
  @spec dispatch(atom(), map(), async: boolean()) :: :ok | {:ok, map()} | {:error, any()}
  def dispatch(command, params, opts \\ []) do
    with {:ok, {aggregate, module}} <- GenServer.call(__MODULE__, {:route_command, command}),
         {:ok, cmd} <- params |> module.new() |> module.validate() do
      aggregate_id = Map.get(cmd, :id, nil)
      async = Keyword.get(opts, :async, false)
      execute_command(aggregate, cmd, aggregate_id, async)
    else
      {:error, _} = error -> error
    end
  end

  @doc """
  Executes a query on the aggregate.
  """
  @spec query(atom(), map()) :: any() | [any]
  def query(query, params) do
    with {:ok, {_, module}} <- GenServer.call(__MODULE__, {:route_query, query}),
         {:ok, query} <- params |> module.new() |> module.validate() do
      apply(module, :run, [query])
    else
      {:error, _} = error -> error
    end
  end

  ## Server calbacks

  @impl true
  def init(%{modules: _} = state) do
    Process.send(self(), :build_routes, [])

    {:ok, state}
  end

  @impl true
  def handle_info(:build_routes, %{modules: modules} = state) do
    routes = Enum.reduce(modules, %{}, &build_module_routes(&2, &1))

    new_state = Map.merge(state, routes)

    {:noreply, new_state}
  end

  @impl true
  def handle_call({:route_command, command}, _from, state) do
    route =
      case state.command[command] do
        nil -> {:error, "unknown command"}
        route -> {:ok, route}
      end

    {:reply, route, state}
  end

  @impl true
  def handle_call({:route_query, query}, _from, state) do
    route =
      case state.queries[query] do
        nil -> {:error, "unknown query"}
        route -> {:ok, route}
      end

    {:reply, route, state}
  end

  @impl true
  def handle_call({:execute_command, aggregate, cmd, id}, _from, state) do
    {:reply, aggregate.handle(cmd, id), state}
  end

  @impl true
  def handle_call(:commands, _from, state) do
    routes = state |> Map.get(:command, %{}) |> Map.keys()
    {:reply, routes, state}
  end

  @impl true
  def handle_call(:queries, _from, state) do
    routes = state |> Map.get(:queries, %{}) |> Map.keys()
    {:reply, routes, state}
  end

  @impl true
  def handle_cast({:execute_command, aggregate, cmd, id}, state) do
    aggregate.handle(cmd, id)

    {:noreply, state}
  end

  defp build_module_routes(current_routes, module) do
    commands = build_routes_for(:commands, module)
    queries = build_routes_for(:queries, module)

    Map.merge(current_routes, %{command: commands, queries: queries})
  end

  defp build_routes_for(key, module) do
    routes = Map.get(module.routes(), key, %{})

    Enum.reduce(routes, %{}, fn {name, command}, acc ->
      route = Map.put(%{}, name, {module, command})
      Map.merge(acc, route)
    end)
  end

  defp execute_command(aggregate, cmd, nil, async) do
    id = UUID.uuid4()
    execute_command(aggregate, cmd, id, async)
  end

  defp execute_command(aggregate, cmd, id, async) do
    case async do
      true ->
        :ok = GenServer.cast(__MODULE__, {:execute_command, aggregate, cmd, id})
        {:ok, id}

      false ->
        GenServer.call(__MODULE__, {:execute_command, aggregate, cmd, id})
    end
  end
end
