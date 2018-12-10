defmodule Disco.EventStore do
  @moduledoc """
  The event store.

  This module is responsible to manage events so that they can be persisted and then retrieved.

  The actual implementation uses PostgreSQL and `Ecto.SQL` to store events. An adapter based
  approach has been planned as one of the next planned features.
  """

  alias Disco.EventStore.Data.Event
  alias Disco.EventStore.Data.EventConsumer
  alias Disco.Repo

  @type event :: %{:type => binary(), optional(atom()) => any()}

  @doc """
  Adds an event to the store.
  """
  @spec emit(event) :: {:ok, result :: event}
  def emit(%{type: _} = event) do
    {:ok, emitted} = event |> Event.changeset_event() |> Repo.insert()

    {:ok, event_to_map(emitted)}
  end

  @doc """
  List events after a given offset.

  If offset is not present (nil), events will start from the beginning.
  """
  @spec load_events_after_offset(events_listened :: [binary], offset :: integer()) :: [map()]
  def load_events_after_offset(events_listened, offset) do
    events_listened
    |> Event.with_types()
    |> Event.after_offset(offset)
    |> Repo.all()
    |> Enum.map(&event_to_map/1)
  end

  @doc """
  List events for a given aggregate id.

  If offset is not present (nil), events will start from the beginning.
  """
  @spec list_events_for_aggregate_id(aggregate_id :: binary()) :: [event]
  def list_events_for_aggregate_id(id) do
    id
    |> Event.with_aggregate_id()
    |> Repo.all()
    |> Enum.map(&event_to_map/1)
  end

  @doc """
  List events for a given set of event types.
  """
  @spec list_events_with_types(event_types :: [binary()]) :: list()
  def list_events_with_types(types) do
    types
    |> Event.with_types()
    |> Repo.all()
    |> Enum.map(&event_to_map/1)
  end

  @doc """
  Returns the offset of an event consumer.
  """
  @spec event_consumer_offset(consumer :: binary()) :: integer()
  def event_consumer_offset(consumer) do
    case get_event_consumer_by_name(consumer) do
      nil -> 0
      event_consumer -> event_consumer.offset
    end
  end

  @doc """
  Updates the offset of an event consumer.

  This function is usually called after an event has been processed.
  """
  @spec update_event_consumer_offset(consumer :: binary(), offset :: integer()) ::
          {:ok, integer()}
  def update_event_consumer_offset(consumer, offset) do
    {:ok, _} =
      consumer
      |> get_event_consumer_by_name()
      |> EventConsumer.update_offset_changeset(consumer, offset)
      |> Repo.insert_or_update()

    {:ok, offset}
  end

  @doc """
  Reset the offset of a given event consumer.

  Useful when you want a consumer to re-process all the events.
  """
  @spec reset_offsets_for_consumer(binary()) :: any()
  def reset_offsets_for_consumer(consumer) when is_binary(consumer) do
    EventConsumer
    |> EventConsumer.by_name(consumer)
    |> Repo.delete_all()
  end

  defp get_event_consumer_by_name(name) do
    EventConsumer
    |> EventConsumer.by_name(name)
    |> Repo.one()
  end

  defp event_to_map(%Event{} = event) do
    event |> Map.from_struct() |> Map.delete(:__meta__) |> Map.delete(:payload_json)
  end
end
