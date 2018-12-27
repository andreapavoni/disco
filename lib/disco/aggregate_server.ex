defmodule Disco.AggregateServer do
  @moduledoc """
  The aggregate server spec.
  """

  defmacro __using__(opts \\ []) do
    routes = Keyword.get(opts, :routes)
    main_event_store_client = Application.get_env(:disco, :event_store_client)
    event_store_client = Keyword.get(opts, :event_store_client, main_event_store_client)

    quote bind_quoted: [routes: routes, event_store_client: event_store_client] do
      use GenServer

      @routes routes
      @event_store_client event_store_client

      ## Client API

      def start_link() do
        GenServer.start_link(__MODULE__, %{registry: %{}}, name: __MODULE__)
      end

      @doc """
      Returns a map of available commands.
      """
      @spec routes() :: %{commands: map(), queries: map()}
      def routes do
        Map.merge(%{commands: %{}, queries: %{}}, @routes)
      end

      @doc """
      Executes command on the aggregate if available. It runs sync.
      """
      @spec dispatch(command :: atom(), params :: map()) :: :ok | {:ok, map()} | {:error, any()}
      def dispatch(command, params) do
        # TODO: add support for async calls like Disco.dispatch
        with {:ok, cmd} <- init_command(command, params) do
          aggregate_id = Map.get(cmd, :id, UUID.uuid4())
          :ok = GenServer.cast(__MODULE__, {:handle, cmd, aggregate_id})

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

      def kill(aggregate_id) do
        GenServer.cast(__MODULE__, {:kill, aggregate_id})
      end

      ## Server callbacks

      def init(state), do: {:ok, state}

      def handle_cast({:handle, command, aggregate_id}, %{registry: registry} = state) do
        {pid, registry} = aggregate_for(registry, aggregate_id)

        result = Disco.AggregateWorker.handle(command, pid)

        {:noreply, %{state | registry: registry}}
      end

      def handle_cast({:kill, aggregate_id}, %{registry: registry} = state) do
        registry =
          case Map.get(registry, aggregate_id) do
            pid when is_pid(pid) ->
              IO.inspect(pid, label: "======= KILLING PID:")
              GenServer.stop(pid)
              Map.delete(registry, aggregate_id)

            _ ->
              IO.inspect(registry, label: "======= NO PID FOUND:")
              registry
          end

        {:noreply, %{state | registry: registry}}
      end

      ## Helpers (callbacks?)

      def load_aggregate_events(id) do
        @event_store_client.load_aggregate_events(id)
      end

      def commit(events) do
        Enum.each(events, &@event_store_client.emit/1)
        :ok
      end

      ## Private functions

      defp init_command(command, params) do
        with cmd_module when not is_nil(cmd_module) <- routes()[:commands][command],
             {:ok, cmd} <- params |> cmd_module.new() |> cmd_module.validate() do
          {:ok, cmd}
        else
          nil -> {:error, "unknown command"}
          {:error, _} = error -> error
        end
      end

      defp get_aggregate_id(command) do
        case Map.get(command, :id) do
          nil -> UUID.uuid4()
          id -> id
        end
      end

      defp aggregate_for(registry, aggregate_id) do
        Map.get_and_update(registry, aggregate_id, &spawn_aggregate(&1, aggregate_id))
      end

      # TODO: use supervisor to spawn and manage aggregate workers
      defp spawn_aggregate(pid, _) when is_pid(pid), do: {pid, pid}

      defp spawn_aggregate(nil, id) do
        {:ok, pid} = Disco.AggregateWorker.start_link(%__MODULE__{id: id})
        {pid, pid}
      end
    end
  end
end
