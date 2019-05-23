defmodule Disco.EventStore.Client do
  @moduledoc """
  The `Disco.EventStore.Client` specification.

  A client is used to interact with `Disco.EventStore` while keeping details isolated.

  Like other components in `Disco`, even the `Disco.EventStore.Client` is built as a
  behaviour that implements default callbacks. This means that the simplest definition of
  a client can be achieved like the following:

  ```
  defmodule MyApp.EventStoreClient do
    use Disco.EventStore.Client
  end
  ```
  """

  @doc """
  Called to emit an event to the event store.
  """
  @callback emit(type :: binary(), payload :: map()) ::
              {:ok, event :: map()} | {:error, reason :: any()}

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
      @spec emit(type :: binary, payload :: map()) :: {:ok, event :: map()}
      def emit(type, %{} = payload), do: Client.build_event(type, payload) |> EventStore.emit()

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

  @doc """
  Builds an event map.
  """
  @spec build_event(type :: binary(), payload :: map()) :: event :: map()
  def build_event(type, payload) do
    %{type: type, payload: Disco.EventPayloadEncoder.encode(payload)}
  end
end
