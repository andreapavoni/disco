defmodule Disco.EventStore.Ecto.PayloadType do
  @moduledoc """
  Defines a custom `Ecto.Type` to handle erlang term serialization on database.
  """

  @behaviour Ecto.Type

  def type, do: :binary

  def cast(%{} = payload), do: {:ok, payload}
  def cast(_), do: :error

  def load(binary), do: {:ok, :erlang.binary_to_term(binary)}

  def dump(payload), do: {:ok, :erlang.term_to_binary(payload)}
end
