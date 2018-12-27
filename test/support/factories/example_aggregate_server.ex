defmodule Disco.Factories.ExampleAggregateServer do
  @moduledoc false

  defstruct id: nil, foo: nil

  use Disco.AggregateServer,
    routes: %{
      commands: %{
        do_something: Disco.Factories.ExampleCommand
      },
      queries: %{
        find_something: Disco.Factories.ExampleQuery
      }
    },
    event_store_client: Disco.EventStore.ClientMock

  def apply_event(%{type: "FooHappened"} = event, state) do
    %{state | foo: event.foo, id: event.aggregate_id}
  end
end
