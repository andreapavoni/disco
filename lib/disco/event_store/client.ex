defmodule Disco.EventStore.Client do
  @moduledoc """
  Macro and behaviour to interact with event store from external apps.
  """

  @doc """
  Called to emit an event to the event store.
  """
  @callback emit(map()) :: {:ok, event :: map()} | {:error, reason :: any()}

  @doc """
  Called to load events for a given aggregate id from event store.
  """
  @callback load_aggregate_events(id :: any()) :: list()

  @doc """
  Called to load emitted events that need to be consumed.
  """
  @callback load_events_with_types(event_types :: [binary()]) :: list()

  @doc """
  Called to obtain the current offset for a given cosumer. Returns `0` by default.
  """
  @callback get_consumer_offset(consumer :: binary()) :: integer()

  @doc """
  Called to load events to be consumed after a given offset.
  """
  @callback load_events_after_offset(events_listened :: [binary], offset :: integer) :: [map()]

  @doc """
  Called to update current offset counter.
  """
  @callback update_consumer_offset(consumer :: binary(), offset :: integer()) :: {:ok, integer()}

  defmacro __using__(_opts) do
    quote do
      @behaviour Disco.EventStore.Client

      alias Disco.EventStore
      alias Disco.EventStore.Client

      @doc """
      Emits an event.
      """
      @spec emit(map()) :: {:ok, event :: map()}
      def emit(%{} = event), do: EventStore.emit(event)

      @doc """
      Loads events for a given aggregate id.
      """
      @spec load_aggregate_events(id :: any()) :: list()
      def load_aggregate_events(id), do: EventStore.list_events_for_aggregate_id(id)

      @doc """
      Loads events with given types.
      """
      @spec load_events_with_types(event_types :: [binary()]) :: list()
      def load_events_with_types(event_types), do: EventStore.list_events_with_types(event_types)

      @doc """
      Returns current offset for a given consumer.
      """
      @spec get_consumer_offset(consumer :: binary()) :: integer()
      def get_consumer_offset(consumer), do: EventStore.event_consumer_offset(consumer)

      @doc """
      Updates current offset counter.
      """
      @spec update_consumer_offset(consumer :: binary(), offset :: integer()) :: {:ok, integer()}
      def update_consumer_offset(consumer, offset) do
        EventStore.update_event_consumer_offset(consumer, offset)
      end

      @doc """
      Loads events emitted after a given offset.
      """
      @spec load_events_after_offset(events_listened :: [binary], offset :: integer()) :: [map()]
      def load_events_after_offset(events_listened, offset) do
        EventStore.load_events_after_offset(events_listened, offset)
      end
    end
  end
end
