defmodule Disco.AggregateTest do
  use Disco.DataCase, async: true

  alias Disco.EventStore.ClientMock, as: EventStoreClientMock
  alias Disco.Factories.ExampleAggregate, as: Aggregate
  alias Disco.Factories.ExampleCommand, as: Command
  alias Disco.Factories.ExampleQuery, as: Query

  import Mox
  setup [:set_mox_global, :verify_on_exit!]

  describe "dispatch/2" do
    test "executes command and applies event to aggregate state" do
      {:ok, _pid} = Aggregate.start_link()

      expect(EventStoreClientMock, :load_aggregate_events, 1, fn _ -> [] end)
      expect(EventStoreClientMock, :emit, 1, fn _ -> {:ok, %{}} end)

      assert {:ok, aggregate_id} = Aggregate.dispatch(:do_something, %{foo: "bar"})
      assert {:ok, _} = UUID.info(aggregate_id)
    end
  end

  test "query/2 executes query and returns data" do
    assert Aggregate.query(:find_something, %{foo: "bar"}) == %{foo: "bar"}
  end

  test "apply_event/1 applies an event to update aggregate state" do
    event = %{type: "FooHappened", aggregate_id: 1, payload: %{foo: "bar"}}
    state = %Aggregate{id: 1, foo: nil}

    assert %Aggregate{id: 1, foo: "bar"} = Aggregate.apply_event(event, state)
  end

  test "routes/0 returns available routes for the aggregate" do
    routes = %{commands: %{do_something: Command}, queries: %{find_something: Query}}

    assert ^routes = Aggregate.routes()
  end
end
