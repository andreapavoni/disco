defmodule Disco.Testing do
  @moduledoc """
  Testing helpers.
  """

  alias Disco.Event

  @doc """
  Returns an event map to be used in tests.
  """
  @spec build_event(attrs :: map(), payload :: map) :: Disco.Event.t()
  def build_event(%{} = attrs \\ %{}, %{} = payload \\ %{}) do
    payload = Map.merge(payload, attrs)

    "SomethingHappened"
    |> Event.build(payload, %{id: UUID.uuid4()})
  end
end
