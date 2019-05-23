defmodule Disco.Query do
  @moduledoc """
  The query specification.

  A query in `Disco` is a struct which has the fields representing potential parameters
  for the query itself.

  This module defines a behaviour with a set of default callback implementations to execute
  a query on an aggregate.

  ## Define a query

  Here's how to implement a simple query without params:
  ```
  defmodule MyApp.QuerySimple do
    use Disco.Query

    def run(%__MODULE__{} = _query), do: "result"
  end
  ```

  If you might need some params:
  ```
  defmodule MyApp.QueryWithParams do
    use Disco.Query, foo: nil

    def run(%__MODULE__{} = query), do: query.foo
  end
  ```

  It's also possible to apply validations on the params. Refer to [Vex](https://github.com/CargoSense/vex) for more details.
  ```
  defmodule MyApp.QueryWithValidations do
    use Disco.Query, foo: nil, bar: nil

    # param `foo` is required, `bar` isn't.
    validates(:foo, presence: true)

    def run(%__MODULE__{} = query), do: query.foo
  end
  ```

  ## Overriding default functions

  As you can see, the simplest implementation only requires to implement `run/1` callback,
  while the others are already implemented by default. Sometimes you might need a custom
  initialization or validation function, that's why it's possible to override `new/1` and
  `validate/1`.

  ## Usage example

  _NOTE: `Disco.Factories.ExampleQuery` has been defined in `test/support/examples/example_query.ex`._

  ```
  iex> alias Disco.Factories.ExampleQuery, as: Query
  iex> Query.new(%{foo: "bar"}) == %Query{foo: "bar"}
  true
  iex> Query.new(%{foo: "bar"}) |> Query.validate()
  {:ok, %Query{foo: "bar"}}
  iex> Query.new() |> Query.validate()
  {:error, %{foo: ["must be present"]}}
  iex> Query.run(%Query{foo: "bar"})
  %{foo: "bar"}
  ```
  """

  @type error :: {:error, %{atom() => [binary()]} | binary()}

  @typedoc """
  Result of the query, it might be anything.
  """
  @type result :: any()

  @doc """
  Called to initialize a query.
  """
  @callback new(params :: map()) :: map()

  @doc """
  Called to validate the query.
  """
  @callback validate(query :: map()) :: {:ok, map()} | error()

  @doc """
  Called to run the query.
  """
  @callback run(query :: map() | error()) :: result()

  @doc """
  Called to init, validate and run the query all at once.

  This function is particularly useful when you don't want to call `new/1`, `validate/1` and
  `run/1` manually.
  """
  @callback execute(params :: map()) :: result()

  @doc """
  Defines the struct fields and the default callbacks to implement the behaviour to run a query.

  ## Options
  The only argument accepted is a Keyword list of fields for the query struct.
  """
  defmacro __using__(attrs) do
    quote do
      @behaviour Disco.Query
      import Disco.Query

      defstruct unquote(attrs)

      use ExConstructor, :init
      use Vex.Struct

      @doc """
      Initializes a query.
      """
      @spec new(params :: map()) :: map()
      def new(%{} = params \\ %{}), do: init(params)

      @doc """
      Validates an initialized query.
      """
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
      @spec execute(params :: map()) :: any()
      def execute(%{} = params \\ %{}) do
        with %__MODULE__{} = cmd_struct <- new(params),
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
