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
  """

  @typedoc """
  Represents the state of an aggregate.
  """
  @type state :: map()

  @doc """
  Called to get the current aggregate state.
  """
  @callback current_state(id :: any()) :: state()

  @doc """
  Called to send emitted events to `Disco.EventStore`.
  """
  @callback commit(events :: list()) :: :ok

  @doc """
  Called to process a list events to update the state.
  """
  @callback process(events :: list(), state()) :: {:ok, state()}

  @doc """
  Called to run a given command and to emit the event(s). Returns updated state.
  """
  @callback handle(command :: map(), aggregate_id :: binary() | nil) :: {:ok, state()}

  @doc """
  Called to apply an event to update the state.
  """
  @callback apply_event(event :: map(), state()) :: state()

  @doc """
  Defines the default callbacks to implement the behaviour, the routes to commands and queries,
  sets the client to communicate with the `Disco.EventStore`.

  ## Options
    * `:routes` - a map with `:commands` and `:queries` as keys, and a map with
      `query_name: query_module` pairs, as value.
    * `:event_store_client` - a module that implements `Disco.EventStore.Client` behaviour.

  """
  defmacro __using__(opts \\ []) do
    routes = Keyword.get(opts, :routes)
    event_store_client = Keyword.get(opts, :event_store_client)

    quote bind_quoted: [routes: routes, event_store_client: event_store_client] do
      @behaviour Disco.Aggregate

      @routes routes
      @event_store_client event_store_client

      @doc """
      Returns a map of available commands.
      """
      @spec routes() :: %{commands: map(), queries: map()}
      def routes do
        Map.merge(%{commands: %{}, queries: %{}}, @routes)
      end

      def current_state(id \\ nil)
      def current_state(nil), do: %__MODULE__{id: UUID.uuid4()}

      def current_state(id) do
        events = @event_store_client.load_aggregate_events(id)
        {:ok, state} = process(events, %__MODULE__{id: id})
        state
      end

      def handle(%module{} = cmd, aggregate_id \\ nil) do
        state = current_state(aggregate_id)

        # run cmd and get events
        events = module.run(cmd, state)

        # process events on the current state
        {:ok, new_state} = process(events, state)

        # commit events to event store
        commit(events)

        {:ok, new_state}
      end

      def commit(events) do
        Enum.each(events, &@event_store_client.emit/1)
        :ok
      end

      def process(events, %cmd_module{} = state) do
        new_state = Enum.reduce(events, state, &cmd_module.apply_event(&1, &2))

        {:ok, new_state}
      end

      @doc """
      Executes command on the aggregate if available. It runs sync.
      """
      @spec dispatch(command :: atom(), params :: map()) :: {:ok, map()} | {:error, any()}
      def dispatch(command, params) do
        # TODO: add support for async calls like Disco.dispatch
        with cmd_module when not is_nil(cmd_module) <- routes()[:commands][command],
             {:ok, cmd} <- params |> cmd_module.new() |> cmd_module.validate() do
          __MODULE__.handle(cmd)
        else
          nil -> {:error, "unknown command"}
          {:error, _} = error -> error
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

      defoverridable current_state: 1, handle: 1, process: 2, commit: 1
    end
  end
end
