defmodule Disco.EventPayloadEncoderError do
  @type t :: %__MODULE__{message: String.t(), value: any}

  defexception message: nil, value: nil

  def message(%{message: nil, value: value}) do
    "unable to serialize value: #{inspect(value)}"
  end

  def message(%{message: message}) do
    message
  end
end

defprotocol Disco.EventPayloadEncoder do
  @fallback_to_any true

  @spec encode(t) :: Map.t()
  def encode(value)
end

defimpl Disco.EventPayloadEncoder, for: Map do
  @compile :inline_list_funcs

  def encode(map), do: map
end

defimpl Disco.EventPayloadEncoder, for: Any do
  alias Disco.EventPayloadEncoder
  alias Disco.EventPayloadEncoderError

  defmacro __deriving__(module, struct, options) do
    deriving(module, struct, options)
  end

  def deriving(module, _struct, options) do
    only = options[:only]
    except = options[:except]

    extractor =
      cond do
        only ->
          quote(do: Map.take(struct, unquote(only)))

        except ->
          except = [:__struct__ | except]
          quote(do: Map.drop(struct, unquote(except)))

        true ->
          quote(do: :maps.remove(:__struct__, struct))
      end

    quote do
      defimpl EventPayloadEncoder, for: unquote(module) do
        def encode(struct) do
          EventPayloadEncoder.Map.encode(unquote(extractor))
        end
      end
    end
  end

  def encode(%{__struct__: _} = struct) do
    EventPayloadEncoder.Map.encode(Map.from_struct(struct))
  end

  def encode(value, _options) do
    raise EventPayloadEncoderError, value: value
  end
end
