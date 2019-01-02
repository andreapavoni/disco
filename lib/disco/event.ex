defmodule Disco.Event do
  @moduledoc """
  The event specification.
  """

  @type t :: %__MODULE__{}

  defstruct id: nil,
            aggregate_id: nil,
            emitted_at: nil,
            type: nil,
            payload: %{},
            payload_json: %{},
            meta: %{}

  @spec build(binary(), map(), %{id: binary()}) :: Disco.Event.t()
  def build(type, payload, %{id: aggregate_id} = _state) do
    raw = %{type: type, aggregate_id: aggregate_id} |> Map.merge(payload)

    %__MODULE__{
      id: UUID.uuid4(),
      aggregate_id: raw.aggregate_id,
      emitted_at: DateTime.utc_now(),
      type: raw.type,
      payload: raw,
      payload_json: raw
    }
  end
end
