defmodule Disco.Factories.ExampleCommand do
  @moduledoc false

  use Disco.Command, foo: nil

  validates(:foo, presence: true)

  def run(%__MODULE__{} = command) do
    command |> Map.from_struct()

    :ok
  end
end
