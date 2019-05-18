defmodule Disco.EventStore.ClientTest do
  use Disco.DataCase, async: false

  defmodule Client do
    use Disco.EventStore.Client
  end

  describe "event store client behaviour when used by a module:" do
    test "emit/1 emits an event to the event store" do
      assert {:ok, event} = Client.emit(build_event())

      refute is_nil(event.id)
      refute is_nil(event.emitted_at)
    end

    test "load_events_with_types/1 loads events with given types" do
      %{id: event_id, type: type} = insert(:event)

      assert [%{type: ^type, id: ^event_id}] = Client.load_events_with_types([type])
    end

    test "get_consumer_offset/1 returns the current offset for a given consumer" do
      assert Client.get_consumer_offset("SomeConsumer") == 0
    end

    test "load_events_after_offset/2 loads events after a given offset" do
      assert Client.load_events_after_offset(["SomeConsumer"], 10) == []
    end

    test "update_consumer_offset/2 updates consumer current offset" do
      assert {:ok, 1} = Client.update_consumer_offset("SomeConsumer", 1)
    end
  end
end
