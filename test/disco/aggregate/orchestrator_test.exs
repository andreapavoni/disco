defmodule Disco.Aggregate.OrchestratorTest do
  use Disco.DataCase, async: false

  alias Disco.Factories.ExampleAggregate, as: Aggregate
  alias Disco.Aggregate.Orchestrator

  import Mox
  setup [:set_mox_global, :verify_on_exit!]

  setup do
    {:ok, _pid} = Orchestrator.start_link([Aggregate])
    :ok
  end

  describe "dispatch/2" do
    test "executes command and applies event to aggregate state" do
      expect(EventStoreClientMock, :emit, fn _ -> :ok end)
      expect(EventStoreClientMock, :load_aggregate_events, fn _ -> [] end)

      assert {:ok, %Aggregate{id: _, foo: "bar"}} =
               Orchestrator.dispatch(:do_something, %{foo: "bar"})
    end

    test "executes command async" do
      expect(EventStoreClientMock, :emit, fn _ -> :ok end)
      expect(EventStoreClientMock, :load_aggregate_events, fn _ -> [] end)

      assert {:ok, id} = Orchestrator.dispatch(:do_something, %{foo: "bar"}, async: true)
      assert {:ok, _} = UUID.info(id)
    end

    test "test returns error when command route is not found" do
      {:error, "unknown command"} = assert Orchestrator.dispatch(:wrong_command, %{foo: "bar"})
    end
  end

  describe "query/2" do
    test "executes query and returns data" do
      assert Orchestrator.query(:find_something, %{foo: "bar"}) == %{foo: "bar"}
    end

    test "test returns error when query route is not found" do
      {:error, "unknown query"} = assert Orchestrator.query(:wrong_query, %{foo: "bar"})
    end
  end

  test "routes/0 returns available routes for the aggregates" do
    routes = %{commands: [:do_something], queries: [:find_something]}

    assert ^routes = Orchestrator.routes()
  end
end
