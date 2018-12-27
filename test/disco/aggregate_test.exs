defmodule Disco.AggregateTest do
  use Disco.DataCase, async: false

  alias Disco.Factories.ExampleAggregate, as: Aggregate
  alias Disco.Factories.ExampleCommand, as: Command
  alias Disco.Factories.ExampleQuery, as: Query

  import Mox
  setup :verify_on_exit!

  describe "aggregate behaviour when used by a module:" do
    test "commit/1 commits events to event store" do
      expect(EventStoreClientMock, :emit, 2, fn %{type: "FooHappened", aggregate_id: _, foo: _} ->
        :ok
      end)

      events = [
        %{type: "FooHappened", aggregate_id: 1, foo: "bar"},
        %{type: "FooHappened", aggregate_id: 2, foo: "baz"}
      ]

      assert :ok = Aggregate.commit(events)
    end

    test "commit/1 doesn't commit empty events to event store" do
      expect(EventStoreClientMock, :emit, 0, fn _ -> :ok end)

      assert :ok = Aggregate.commit([])
    end

    test "process/1 applies events to update aggregate state" do
      events = [
        %Disco.Event{type: "FooHappened", aggregate_id: 1, payload: %{foo: "bar"}},
        %Disco.Event{type: "FooHappened", aggregate_id: 1, payload: %{foo: "baz"}}
      ]

      state = %Aggregate{id: 1, foo: nil}

      assert {:ok, %Aggregate{id: 1, foo: "baz"}} = Aggregate.process(events, state)
    end

    test "handle/2 runs a given command, emits the event(s) and returns updated state" do
      expect(EventStoreClientMock, :emit, fn %Disco.Event{
                                               type: "FooHappened",
                                               aggregate_id: _,
                                               payload: %{foo: "bar"}
                                             } ->
        :ok
      end)

      assert {:ok, %Aggregate{id: id, foo: "bar"}} = Aggregate.handle(%Command{foo: "bar"})
      refute is_nil(id)
    end

    test "apply_event/1 applies an event to update aggregate state" do
      event = %{type: "FooHappened", aggregate_id: 1, payload: %{foo: "bar"}}
      state = %Aggregate{id: 1, foo: nil}

      assert %Aggregate{id: 1, foo: "bar"} = Aggregate.apply_event(event, state)
    end

    test "current_state/1 returns the current aggregate state" do
      expect(EventStoreClientMock, :load_aggregate_events, fn 1 ->
        [%Disco.Event{type: "FooHappened", id: 1, aggregate_id: 1, payload: %{foo: "bar"}}]
      end)

      assert %Aggregate{foo: "bar", id: 1} = Aggregate.current_state(1)
    end

    test "routes/0 returns available routes for the aggregate" do
      routes = %{commands: %{do_something: Command}, queries: %{find_something: Query}}
      assert ^routes = Aggregate.routes()
    end

    test "dispatch/2 executes a command to aggregate" do
      expect(EventStoreClientMock, :emit, fn %{
                                               type: "FooHappened",
                                               aggregate_id: _,
                                               payload: %{foo: "bar"}
                                             } ->
        :ok
      end)

      assert {:ok, %Aggregate{foo: "bar", id: _}} =
               Aggregate.dispatch(:do_something, %{foo: "bar"})
    end

    test "query/2 executes a query to aggregate" do
      assert Aggregate.query(:find_something, %{foo: "bar"}) == %{foo: "bar"}
    end
  end
end
