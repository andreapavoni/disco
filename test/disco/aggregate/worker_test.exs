defmodule Disco.Aggregate.WorkerTest do
  use Disco.DataCase, async: false

  alias Disco.Aggregate.Worker
  alias Disco.Event
  alias Disco.Factories.ExampleAggregate, as: Aggregate
  alias Disco.Factories.ExampleCommand, as: Command

  import Mox
  setup [:set_mox_global, :verify_on_exit!]

  setup do
    expect(EventStoreClientMock, :load_aggregate_events, fn _ -> [] end)

    {:ok, pid} = Worker.start_link(%Aggregate{id: UUID.uuid4()})

    {:ok, %{pid: pid}}
  end

  describe "process/2" do
    test "applies events to aggregate state", %{pid: pid} do
      assert %Aggregate{foo: nil, id: _} = Worker.process([], pid)
    end
  end

  describe "handle/2" do
    test "handles command", %{pid: pid} do
      expect(EventStoreClientMock, :emit, fn _ -> :ok end)

      command = %Command{foo: "123"}
      assert [%Event{type: "FooHappened"}] = Worker.handle(command, pid)
    end
  end
end
