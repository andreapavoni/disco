defmodule Disco.AggregateServerTest do
  use Disco.DataCase, async: false

  alias Disco.Factories.ExampleAggregateServer, as: AggregateServer

  describe "dispatch/2" do
    test "executes command and applies event to aggregate state" do
      {:ok, _pid} = AggregateServer.start_link()

      assert {:ok, aggregate_id} = AggregateServer.dispatch(:do_something, %{foo: "bar"})
      assert {:ok, _} = UUID.info(aggregate_id)
    end
  end

  test "query/2 executes query and returns data" do
    assert AggregateServer.query(:find_something, %{foo: "bar"}) == %{foo: "bar"}
  end
end
