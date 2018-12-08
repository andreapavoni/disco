defmodule Disco.Factories.ExampleCommand do
  @moduledoc false

  use Disco.Command, foo: nil

  validates(:foo, presence: true)

  def run(%__MODULE__{} = command, state) do
    body =
      command
      |> Map.from_struct()
      |> Map.put(:aggregate_id, state.id)

    [build_event("FooHappened", body, state)]
  end
end
