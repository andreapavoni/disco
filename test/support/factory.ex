defmodule Disco.Factory do
  @moduledoc """
  Factories for EventStore app.
  """
  use ExMachina.Ecto, repo: Disco.Repo

  alias Disco.EventStore.Data.Event

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
      emitted_at: timestamp,
      inserted_at: timestamp,
      offset: nil,
      payload: payload,
      payload_json: payload
    }
  end
end
