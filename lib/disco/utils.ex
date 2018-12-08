defmodule Disco.Utils do
  @moduledoc """
  Shared helpers.
  """

  @doc """
  Removes nil values from a map or struct.

  ## Examples

    iex> Disco.Utils.map_reject_nil_values(%{foo: "bar", baz: nil})
    %{foo: "bar"}
    iex> opts = [except: [:baz]]
    iex> Disco.Utils.map_reject_nil_values(%{foo: "bar", baz: nil}, opts)
    %{foo: "bar", baz: nil}

  """
  def map_reject_nil_values(data, opts \\ [])

  def map_reject_nil_values(%_{} = struct, opts) do
    struct
    |> Map.from_struct()
    |> map_reject_nil_values(opts)
  end

  def map_reject_nil_values(%{} = map, opts) do
    exclude_keys = Keyword.get(opts, :except, [])

    map
    |> Enum.reject(fn {k, v} -> is_nil(v) and k not in exclude_keys end)
    |> Enum.into(%{})
  end
end
