defmodule Disco.Query do
  @moduledoc """
  Helper macro and behaviour to define a query.

  It can be `use`d as a macro to quickly implement the required functions for the behaviour,
  otherwise they must be implemented explicitly.
  """

  @type error :: {:error, %{atom() => [binary()]} | binary()}

  @doc """
  Called to initialize a query.
  """
  @callback new(query :: map()) :: map()

  @doc """
  Called to validate the query.
  """
  @callback validate(query :: map()) :: {:ok, map()} | error

  @doc """
  Called to run the query.
  """
  @callback run(query :: map() | error) :: any() | [any()]

  @doc """
  Called to init, validate and run the query all at once.
  """
  @callback execute(map()) :: any()

  defmacro __using__(attrs) do
    quote do
      @behaviour Disco.Query
      import Disco.Query

      defstruct unquote(attrs)

      use ExConstructor, :init
      use Vex.Struct

      @spec new(query :: map()) :: map()
      def new(%{} = attrs), do: init(attrs)

      @spec validate(query :: map()) :: {:ok, map()} | Disco.Query.error()
      def validate(%__MODULE__{} = query) do
        case Vex.validate(query) do
          {:ok, query} = ok -> ok
          {:error, errors} -> {:error, handle_validation_errors(errors)}
        end
      end

      @doc """
      Inits, validates and runs the query all at once.
      """
      @spec execute(attrs :: map()) :: any()
      def execute(attrs) do
        with %__MODULE__{} = cmd_struct <- new(attrs),
             {:ok, cmd} <- validate(cmd_struct) do
          run(cmd)
        else
          {:error, _errors} = error -> error
        end
      end

      @spec struct_to_map(struct :: map()) :: map()
      @doc """
      Converts a struct like `Ecto.Schema` to normal maps.
      """
      def struct_to_map(struct) do
        struct
        |> Map.from_struct()
        |> Map.delete(:__meta__)
      end

      defoverridable new: 1, validate: 1, struct_to_map: 1
    end
  end

  @doc false
  def handle_validation_errors(errors) do
    Enum.reduce(errors, %{}, fn {_, key, _, msg}, acc ->
      Map.put(acc, key, [msg])
    end)
  end
end
