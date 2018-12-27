defmodule Disco.EventStoreTest do
  use Disco.DataCase, async: false

  alias Disco.EventStore

  describe "emit/1" do
    test "raises error when event misses 'type' attribute" do
      assert_raise FunctionClauseError, fn ->
        EventStore.emit(%{foo: "bar"})
      end
    end

    test "stores an event correctly without payload" do
      event = build_event()

      assert {:ok, emitted} = EventStore.emit(event)
      assert emitted.type == event.type
      assert %{type: _, aggregate_id: _} = emitted.payload
    end

    test "stores an event correctly with payload" do
      event = build_event(%{foo: 10.0, bar: Date.utc_today(), baz: "hello"})

      assert {:ok, emitted} = EventStore.emit(event)
      assert emitted.payload.foo == event.payload.foo
      assert emitted.payload.bar == event.payload.bar
      assert emitted.payload.baz == event.payload.baz
    end

    # TODO: move this test elsewhere, maybe when testing for ecto adapter
    # test "sets offset bigger than 0" do
    #   assert {:ok, event} = EventStore.emit(build_event())
    #   assert event.offset > 0
    # end
  end
end
