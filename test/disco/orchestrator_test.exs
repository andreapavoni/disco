defmodule Disco.OrchestratorTest do
  use Disco.DataCase, async: false

  alias Disco.Orchestrator
  alias Disco.Factories.ExampleAggregate, as: Aggregate

  import Mox
  setup [:set_mox_global, :verify_on_exit!]

  setup do
    {:ok, _pid} = Orchestrator.start_link([Disco.Factories.ExampleAggregate])
    :ok
  end

  test "commands/0" do
    assert Orchestrator.commands() == [:do_something]
  end

  test "queries/0" do
    assert Orchestrator.queries() == [:find_something]
  end

  describe "dispatch/2" do
    test "executes command and applies event to aggregate state" do
      expect(EventStoreClientMock, :emit, fn _ -> :ok end)
      expect(EventStoreClientMock, :load_aggregate_events, fn _ -> [] end)

      assert {:ok, %Aggregate{id: _, foo: "bar"}} =
               Orchestrator.dispatch(:do_something, %{foo: "bar"})
    end

    test "executes command async" do
      assert {:ok, id} = Orchestrator.dispatch(:do_something, %{foo: "bar"}, async: true)
      assert {:ok, _} = UUID.info(id)
    end
  end

  test "query/2 executes query and returns data" do
    assert Orchestrator.query(:find_something, %{foo: "bar"}) == %{foo: "bar"}
  end
end
