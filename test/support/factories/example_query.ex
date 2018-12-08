defmodule Disco.Factories.ExampleQuery do
  @moduledoc false

  use Disco.Query, foo: nil

  validates(:foo, presence: true)

  def run(%__MODULE__{} = _query) do
    %{foo: "bar"}
  end
end
