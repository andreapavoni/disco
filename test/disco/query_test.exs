defmodule Disco.QueryTest do
  use Disco.DataCase, async: false

  alias Disco.Factories.ExampleQuery, as: Query

  describe "query behaviour when used by a module:" do
    test "new/1 initializes a new query from a map" do
      assert %Query{foo: "bar"} = Query.new(%{"foo" => "bar"})
      assert %Query{foo: "bar"} = Query.new(%{foo: "bar"})
    end

    test "validate/1 validates the query struct" do
      assert {:ok, %Query{}} = Query.validate(%Query{foo: "bar"})
      assert {:error, %{foo: ["must be present"]}} = Query.validate(%Query{})
    end

    test "run/2 runs the query" do
      cmd = %Query{foo: "bar"}
      assert %{foo: "bar"} = Query.run(cmd)
    end

    test "execute/2 inits, validates and runs a query all at once" do
      attrs = %{"foo" => "bar"}
      assert %{foo: "bar"} = Query.execute(attrs)
    end
  end
end
