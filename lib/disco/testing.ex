defmodule Disco.Testing do
  @moduledoc """
  Testing helpers.
  """

  @doc """
  Returns an event map to be used in tests.
  """
  @spec build_event(attrs :: map(), payload :: map) :: event :: map()
  def build_event(%{} = attrs \\ %{}, %{} = payload \\ %{}) do
    timestamp = DateTime.utc_now()

    %{
      id: UUID.uuid4(),
      type: "SomethingHappened",
      emitted_at: timestamp,
      inserted_at: timestamp,
      offset: nil,
      payload: payload,
      payload_json: payload
    }
    |> Map.merge(attrs)
  end
end
