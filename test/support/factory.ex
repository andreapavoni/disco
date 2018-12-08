defmodule Disco.Factory do
  @moduledoc """
  Factories for EventStore app.
  """
  use ExMachina.Ecto, repo: Disco.Repo

  alias Disco.Data.Event

  def build_event(%{} = attrs \\ %{}, %{} = payload \\ %{}) do
    timestamp = DateTime.utc_now()

    %{
      id: UUID.uuid4(),
      type: "SomethingHappened",
      aggregate_id: UUID.uuid4(),
      emitted_at: timestamp,
      inserted_at: timestamp,
      offset: nil,
      payload: payload,
      payload_json: payload
    }
    |> Map.merge(attrs)
  end

  def event_factory do
    timestamp = DateTime.utc_now()

    payload = %{
      user_id: UUID.uuid4(),
      day: Date.utc_today(),
      balance: 10.0
    }

    %Event{
      id: UUID.uuid4(),
      type: "SomethingHappened",
      aggregate_id: UUID.uuid4(),
      emitted_at: timestamp,
      inserted_at: timestamp,
      offset: nil,
      payload: payload,
      payload_json: payload
    }
  end
end
