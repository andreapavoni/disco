defmodule Disco.Aggregate do
  @moduledoc """
  Aggregate macro and behaviour.
  """

  @doc """
  Called to get the current aggregate state.
  """
  @callback current_state(id :: any()) :: any()

  @doc """
  Called to broadcast events to event store.
  """
  @callback commit(list()) :: :ok

  @doc """
  Called to process a list events to update the state.
  """
  @callback process(list(), map()) :: {:ok, map()}

  @doc """
  Called to run a given command and to emit the event(s). Returns updated state.
  """
  @callback handle(command :: map(), aggregate_id :: binary() | nil) :: {:ok, map()}

  @doc """
  Called to apply an event to update the state.
  """
  @callback apply_event(map(), map()) :: map()

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
