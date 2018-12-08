defmodule Disco.Command do
  @moduledoc """
  Helper macro and behaviour to define a command.

  It can be `use`d as a macro to quickly implement the required functions for the behaviour,
  otherwise they must be implemented explicitly.
  """

  @type error :: {:error, %{atom() => [binary()]} | binary()}

  @doc """
  Called to initialize a command.
  """
  @callback new(command :: map()) :: map()

  @doc """
  Called to validate the command.
  """
  @callback validate(command :: map()) :: {:ok, map()} | error

  @doc """
  Called to run the command.
  """
  @callback run(command :: map() | error, state :: map()) :: [event :: map()] | error

  @doc """
  Called to init, validate and run the command all at once.
  """
  @callback execute(map()) :: any()

  defmacro __using__(attrs) do
    quote do
      @behaviour Disco.Command
      import Disco.Command

      defstruct unquote(attrs)

      use ExConstructor, :init
      use Vex.Struct

      @spec new(command :: map()) :: map()
      def new(%{} = attrs), do: init(attrs)

      @spec validate(command :: map()) :: {:ok, map()} | Disco.Command.error()
      def validate(%__MODULE__{} = command) do
        case Vex.validate(command) do
          {:ok, command} = ok -> ok
          {:error, errors} -> {:error, handle_validation_errors(errors)}
        end
      end

      @doc """
      Inits, validates and runs the command all at once.
      """
      @spec execute(attrs :: map(), state :: map()) :: any()
      def execute(attrs, %{} = state \\ %{}) do
        with %__MODULE__{} = cmd_struct <- new(attrs),
             {:ok, cmd} <- validate(cmd_struct) do
          run(cmd, state)
        else
          {:error, _errors} = error -> error
        end
      end

      defoverridable new: 1, validate: 1
    end
  end

  @doc false
  def handle_validation_errors(errors) do
    Enum.reduce(errors, %{}, fn {_, key, _, msg}, acc ->
      Map.put(acc, key, [msg])
    end)
  end

  @spec build_event(binary(), map(), map()) :: map()
  @doc """
  Builds an event map.
  """
  def build_event(type, body, %{id: aggregate_id}) do
    %{type: type, aggregate_id: aggregate_id}
    |> Map.merge(body)
  end
end
