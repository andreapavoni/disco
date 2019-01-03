defmodule Disco.Aggregate do
  @moduledoc """
  The aggregate specification.

  An aggregate in `Disco` is a struct which has the fields representing the state of itself.

  This module defines a behaviour with a set of default callback implementations to execute
  a command or a query on the aggregate.

  ## Define an aggregate

  Here's how to implement a simple aggregate:
  ```
  defmodule MyApp.Aggregate do
    defstruct id: nil, foo: nil

    use Disco.Aggregate,
      routes: %{
        commands: %{
          do_something: MyApp.Commands.DoSomething
        },
        queries: %{
          find_something: MyApp.Commands.FindSomething
        }
      },
      event_store_client: MyApp.EventStoreClient

    def apply_event(%{type: "SomethingDone"} = event, state) do
      %{state | foo: event.foo, id: event.aggregate_id}
    end
  end
  ```

  #### NOTE
  It is very important to _always_ specify an `id` field in the aggregate struct.
  Every aggregate needs it to be uniquely identified.

  ## Overriding default functions

  The simplest implementation only requires to implement `apply_event/2` callback,
  while the others are already implemented by default. Sometimes you might need a custom
  implementation of the callbacks, that's why it's possible to easily override them.

  ## Usage example

  _NOTE: `Disco.Factories.ExampleAggregate` has been defined in `test/support/examples/example_aggregate.ex`._

  ```
  iex> alias Disco.Factories.ExampleAggregate, as: Aggregate
  iex> Aggregate.commands()
  [:do_something]
  iex> Aggregate.routes()
  [:find_something]
  iex> Aggregate.dispatch(:do_something, %{foo: "bar"})
  {:ok, %Disco.Factories.ExampleAggregate{
    foo: "bar",
    id: "4fd98a9e-8d6f-4e35-a8fc-aca5544596cb"
  }}
  iex> Aggregate.query(:find_something, %{foo: "bar"})
  %{foo: "bar"}
  ```

  # Umbrella apps
  Check `Disco.Aggregate.Orchestrator`.
  """

  defmacro __using__(opts \\ []) do
    routes = Keyword.get(opts, :routes)
    main_event_store_client = Application.get_env(:disco, :event_store_client)
    event_store_client = Keyword.get(opts, :event_store_client, main_event_store_client)

    quote bind_quoted: [routes: routes, event_store_client: event_store_client] do
      use DynamicSupervisor

      alias Disco.Aggregate.Worker

      @routes routes
      @event_store_client event_store_client

      ## Client API

      def start_link(_ \\ nil) do
        DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
      end

      @doc """
      Returns a map of available commands and queries.
      """
      @spec routes() :: %{commands: map(), queries: map()}
      def routes, do: @routes

      @doc """
      Executes command on the aggregate if available. It runs sync.
      """
      @spec dispatch(command :: atom(), params :: map(), opts :: list()) ::
              :ok | {:ok, map()} | {:error, any()}
      def dispatch(command, params, opts \\ []) do
        # TODO: add support for async calls like Disco.dispatch
        with {:ok, cmd} <- init_command(command, params) do
          aggregate_id = Map.get(cmd, :id, UUID.uuid4())

          {:ok, pid} = spawn_aggregate(aggregate_id)

          Worker.handle(cmd, pid)

          {:ok, aggregate_id}
        else
          error -> error
        end
      end

      @doc """
      Executes a query on the aggregate.
      """
      @spec query(query :: atom(), params :: map()) :: any() | [any]
      def query(query, params) do
        with module when not is_nil(module) <- routes()[:queries][query],
             {:ok, query} <- params |> module.new() |> module.validate() do
          apply(module, :run, [query])
        else
          {:error, _} = error -> error
        end
      end

      @doc """
      Returns a list of active aggregates.
      """
      def aggregates do
        DynamicSupervisor.which_children(__MODULE__)
      end

      ## Server callbacks

      def init(:ok) do
        DynamicSupervisor.init(strategy: :one_for_one)
      end

      ## Helpers (callbacks?)

      @doc """
      Loads events for a given aggregate id.
      """
      def load_aggregate_events(id) do
        @event_store_client.load_aggregate_events(id)
      end

      @doc """
      Commits events to the event store.
      """
      def commit(events) do
        Enum.each(events, &@event_store_client.emit/1)
        :ok
      end

      ## Private helpers

      defp spawn_aggregate(aggregate_id) do
        child_spec = {Worker, %__MODULE__{id: aggregate_id}}

        case DynamicSupervisor.start_child(__MODULE__, child_spec) do
          {:ok, pid} -> {:ok, pid}
          {:error, {:already_started, pid}} -> {:ok, pid}
          {:error, _} = error -> error
        end

        # {:error, {:already_started, #PID<0.369.0>}}
      end

      defp init_command(command, params) do
        with cmd_module when not is_nil(cmd_module) <- routes()[:commands][command],
             {:ok, cmd} <- params |> cmd_module.new() |> cmd_module.validate() do
          {:ok, cmd}
        else
          nil -> {:error, "unknown command"}
          {:error, _} = error -> error
        end
      end
    end
  end
end
