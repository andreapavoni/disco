defmodule Disco.EventStore do
  @moduledoc """
  The event store.

  This module is responsible to manage events so that they can be persisted and then retrieved.

  The actual implementation uses PostgreSQL and `Ecto.SQL` to store events. An adapter based
  approach has been planned as one of the next planned features.
  """

  alias Disco.EventStore.Data.EventConsumerSchema
  alias Disco.EventStore.Data.EventSchema
  alias Disco.Repo

  @type event :: Disco.Event.t()

  @doc """
  Adds an event to the store.
  """
  @spec emit(Disco.Event.t()) :: {:ok, Disco.Event.t()}
  def emit(%Disco.Event{type: _} = event) do
    {:ok, emitted} = event |> EventSchema.changeset_event() |> Repo.insert()

    {:ok, schema_to_event(emitted)}
  end

  @doc """
  List events after a given offset.

  If offset is not present (nil), events will start from the beginning.
  """
  @spec load_events_after_offset(events_listened :: [binary], offset :: integer()) :: [map()]
  def load_events_after_offset(events_listened, offset) do
    events_listened
    |> EventSchema.with_types()
    |> EventSchema.after_offset(offset)
    |> Repo.all()
    |> Enum.map(&schema_to_event/1)
  end

  @doc """
  List events for a given aggregate id.

  If offset is not present (nil), events will start from the beginning.
  """
  @spec list_events_for_aggregate_id(aggregate_id :: binary()) :: [event]
  def list_events_for_aggregate_id(id) do
    id
    |> EventSchema.with_aggregate_id()
    |> Repo.all()
    |> Enum.map(&schema_to_event/1)
  end

  @doc """
  List events for a given set of event types.
  """
  @spec list_events_with_types(event_types :: [binary()]) :: list()
  def list_events_with_types(types) do
    types
    |> EventSchema.with_types()
    |> Repo.all()
    |> Enum.map(&schema_to_event/1)
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
      |> EventConsumerSchema.update_offset_changeset(consumer, offset)
      |> Repo.insert_or_update()

    {:ok, offset}
  end

  @doc """
  Reset the offset of a given event consumer.

  Useful when you want a consumer to re-process all the events.
  """
  @spec reset_offsets_for_consumer(binary()) :: any()
  def reset_offsets_for_consumer(consumer) when is_binary(consumer) do
    EventConsumerSchema
    |> EventConsumerSchema.by_name(consumer)
    |> Repo.delete_all()
  end

  defp get_event_consumer_by_name(name) do
    EventConsumerSchema
    |> EventConsumerSchema.by_name(name)
    |> Repo.one()
  end

  defp schema_to_event(%EventSchema{} = event) do
    map =
      event
      |> Map.from_struct()
      |> Map.delete(:__meta__)
      |> Map.delete(:inserted_at)
      |> Map.delete(:updated_at)
      |> Map.put(:meta, %{offset: event.offset})
      |> Map.delete(:offset)

    struct(Disco.Event, map)
  end
end
