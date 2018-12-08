defmodule Disco.EventConsumer do
  @moduledoc """
  Macro to implement Disco.EventConsumer behaviour.
  """

  @type error :: {:error, reason :: any}
  @type retry :: {:retry, reason :: any}

  @callback process(event :: map()) :: :ok | {:ok, result :: any()} | error | retry

  defmacro __using__(opts \\ []) do
    event_store = Keyword.get(opts, :event_store_client)
    events_listened = Keyword.get(opts, :events, [])

    quote bind_quoted: [event_store: event_store, events_listened: events_listened] do
      use GenServer
      require Logger

      @behaviour Disco.EventConsumer

      @polling_interval 5000
      @event_store event_store
      @events_listened events_listened

      ## Client API

      def start_link(opts \\ []) do
        initial_state = %{
          polling_interval: Keyword.get(opts, :polling_interval, @polling_interval),
          consumer: Atom.to_string(__MODULE__)
        }

        case Enum.empty?(@events_listened) do
          true -> {:error, "No events to listen for #{initial_state.consumer}"}
          false -> GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
        end
      end

      ## Server callbacks

      def init(%{consumer: consumer, polling_interval: interval}) do
        events_offset = @event_store.get_consumer_offset(consumer)
        Process.send_after(self(), :process, interval)

        {:ok,
         %{
           consumer: consumer,
           events_offset: events_offset,
           polling_interval: interval
         }}
      end

      def handle_info(:process, state) do
        events = @event_store.load_events_after_offset(@events_listened, state.events_offset)
        log_events_to_consume(state.consumer, events)

        offset = Enum.reduce(events, state.events_offset, &do_process(state.consumer, &1, &2))

        Process.send_after(self(), :process, state.polling_interval)

        {:noreply, %{state | events_offset: offset}}
      end

      defp do_process(consumer, event, current_offset) do
        # TODO: handle exceptions
        # TODO: handle when we cannot update the offset
        # TODO: handle dead letters when we cannot retry
        offset =
          case process(event) do
            :ok ->
              event.offset

            {:ok, _} ->
              event.offset

            # something bad happened but we can retry later
            {:retry, _reason} ->
              current_offset

            # something bad happened and retry is not going to work
            {:error, _reason} ->
              event.offset
          end

        {:ok, new_offset} = @event_store.update_consumer_offset(consumer, offset)
        new_offset
      end

      defp log_events_to_consume(consumer, events) do
        events_counter = Enum.count(events)

        if events_counter > 0 do
          Logger.info("#{consumer}: found #{events_counter} events to process")
        end
      end
    end
  end
end
