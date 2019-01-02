defmodule Disco.EventConsumer do
  @moduledoc """
  The event consumer specification.

  An event consumer in `Disco` is a module that exposes a `process/1` function to handle
  a given set of event types. The common use cases are _projections_ and _policies_.

  ### Projections

  A projection is the component that builds or updates a read model, usually optimized
  for queries. It's related to the `Q` in `CQRS` pattern. In this scenario, `process/1`
  will model the data optimizing it for read. One of the most powerful advantages is that,
  later in the future, you might want to build new read models, or rebuild old ones from
  scratch after some iteration. It will suffice to change `process/1` implementation and
  re-process all the events from scratch.

  ### Policies

  A policy is an action to take when some event has happened. You should think carefully
  wether you want to either put that action in a policy or wrap it in a command. This is
  because somewhere in the future you might need to re-process all the events from scratch,
  thus the action you want to take should be repeatable without having annoying side effects.

  ## How it works by default

  This module implements a `GenServer` behaviour with all the callbacks to poll a `Disco.EventStore`
  through a `Disco.EventStore.Client` at given intervals.

  Polling the `Disco.EventStore` is a very simple solution that offers more guarantees
  for consuming all the events without leaving somothing behind. By default, polling interval
  is set to `2000` ms, however it's possible to set a different values globally orper-consumer.
  Here's how to do it:

  ```
  # config/config.exs

  # set polling interval for all the event consumers
  config :disco, :default_polling_interval, 3000

  # set polling interval only for a specific event consumer
  config :disco, MyApp.SomeEventConsumer, 10000
  ```

  ## Define an event consumer

  ```
  defmodule MyApp.SomePolicy do
    use Disco.EventConsumer,
      event_store_client: Application.get_env(:my_app, :event_store_client),
      events: ["SomethingHappened"]

    def process(%{type: "SomethingHappened", payload: payload} = event) do
      # do something with this event
      :ok
    end
  end
  ```
  """

  @type error :: {:error, reason :: any}
  @type retry :: {:retry, reason :: any}

  @callback process(Disco.Event.t()) :: :ok | {:ok, result :: any()} | error | retry

  @doc """
  Defines the default callbacks to implement the `Disco.EventConsumer` behaviour.

  ## Options
    * `:events` - a list of event types to listen.
    * `:event_store_client` - a module that implements `Disco.EventStore.Client` behaviour.
  """
  defmacro __using__(opts) do
    event_store = Keyword.get(opts, :event_store_client)
    events_listened = Keyword.get(opts, :events, [])

    quote bind_quoted: [event_store: event_store, events_listened: events_listened] do
      use GenServer
      require Logger

      @behaviour Disco.EventConsumer

      @default_polling_interval Application.get_env(:disco, :default_polling_interval, 2000)
      @polling_interval Application.get_env(:disco, __MODULE__, @default_polling_interval)
      @event_store event_store
      @events_listened events_listened

      ## Client API

      def start_link(opts \\ []) do
        initial_state = %{
          polling_interval: Keyword.get(opts, :polling_interval, @polling_interval),
          consumer: Atom.to_string(__MODULE__)
        }

        case Enum.empty?(@events_listened) || is_nil(@event_store) do
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
              event.meta.offset

            {:ok, _} ->
              event.meta.offset

            # something bad happened but we can retry later
            {:retry, _reason} ->
              current_offset

            # something bad happened and retry is not going to work
            {:error, _reason} ->
              event.meta.offset
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
