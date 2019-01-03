defmodule Disco.Aggregate.Orchestrator do
  @moduledoc """
  Orchestrates multiple `Disco.Aggregate` together.

  This module is a `GenServer` implementation that can handle more than one aggregate in
  the same place. A common problem, for example, arises when working with [umbrella projects](https://elixir-lang.org/getting-started/mix-otp/dependencies-and-umbrella-projects.html#umbrella-projects),
  where a module can be used to run all the commands and queries without exposing internal
  list of available aggregates.

  ## Usage example

  The usage is similar to `Disco.Aggregate`, except that it supervises many aggregates.

  _NOTE:_ `Disco.Factories.ExampleAggregate` has been defined in `test/support/examples/example_aggregate.ex`.

  ```
  iex> {:ok, pid} = Disco.Aggregate.Orchestrator.start_link [Disco.Factories.ExampleAggregate]
  iex> is_pid(pid)
  true
  iex> Disco.Aggregate.Orchestrator.routes()
  %{commands: [:do_something], queries: [:find_something]}
  iex> Disco.Aggregate.Orchestrator.dispatch(:do_something, %{foo: "bar"})
  {:ok, %Disco.Factories.ExampleAggregate{foo: "bar", id: "4fd98a9e-8d6f-4e35-a8fc-aca5544596cb"}}
  iex> Disco.Aggregate.Orchestrator.query(:find_something, %{foo: "bar"})
  %{foo: "bar"}
  ```
  """

  use GenServer

  @type command_result :: :ok | {:ok, map()} | {:error, any()}

  ## Client API

  @spec start_link(list()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(modules) when is_list(modules) do
    GenServer.start_link(__MODULE__, %{modules: modules}, name: __MODULE__)
  end

  @doc """
  Returns a map of available commands and queries lists.
  """
  def routes do
    GenServer.call(__MODULE__, :routes)
  end

  @doc """
  Executes a command if available. It runs sync by default, use `async: true` option to
  run async.
  """
  @spec dispatch(command :: atom(), params :: map(), async: boolean()) :: command_result

  def dispatch(command, params, opts \\ []) do
    with {:ok, aggregate} <- GenServer.call(__MODULE__, {:route_command, command}) do
      aggregate.dispatch(command, params, opts)
    else
      {:error, _} = error -> error
    end
  end

  @doc """
  Executes a query on one of the available aggregates.
  """
  @spec query(query :: atom(), params :: map()) :: result :: any() | [any]
  def query(query, params) do
    with {:ok, aggregate} <- GenServer.call(__MODULE__, {:route_query, query}) do
      aggregate.query(query, params)
    else
      {:error, _} = error -> error
    end
  end

  ## Server calbacks

  @impl true
  @spec init(%{modules: list()}) :: {:ok, %{modules: list()}}
  def init(%{modules: _} = state) do
    send(self(), :start_supervisor)
    send(self(), :build_routes)

    {:ok, state}
  end

  @impl true
  def handle_call({:route_command, command}, _from, state) do
    route =
      case state.commands[command] do
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
  def handle_call(:routes, _from, state) do
    routes = %{commands: Map.keys(state.commands), queries: Map.keys(state.queries)}

    {:reply, routes, state}
  end

  @impl true
  def handle_info(:build_routes, %{modules: modules} = state) do
    routes = Enum.reduce(modules, %{}, &build_module_routes(&2, &1))

    new_state = Map.merge(state, routes)

    {:noreply, new_state}
  end

  @impl true
  def handle_info(:start_supervisor, %{modules: modules} = state) do
    children = Enum.map(modules, &{&1, []})
    opts = [strategy: :one_for_one, name: Disco.Aggregate.Supervisor]

    Supervisor.start_link(children, opts)

    {:noreply, state}
  end

  defp build_module_routes(current_routes, module) do
    commands = build_routes_for(:commands, module)
    queries = build_routes_for(:queries, module)

    Map.merge(current_routes, %{commands: commands, queries: queries})
  end

  defp build_routes_for(key, module) do
    routes = Map.get(module.routes(), key, %{})

    Enum.reduce(routes, %{}, fn {name, _command}, acc ->
      route = Map.put(%{}, name, module)
      Map.merge(acc, route)
    end)
  end
end
