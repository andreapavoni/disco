defmodule Disco.CommandTest do
  use Disco.DataCase, async: false

  alias Disco.Factories.ExampleCommand, as: Command

  describe "command behaviour when used by a module:" do
    test "new/1 initializes a new command from a map" do
      assert %Command{foo: "bar"} = Command.new(%{"foo" => "bar"})
      assert %Command{foo: "bar"} = Command.new(%{foo: "bar"})
    end

    test "validate/1 validates the command struct" do
      assert {:ok, %Command{}} = Command.validate(%Command{foo: "bar"})
      assert {:error, %{foo: ["must be present"]}} = Command.validate(%Command{})
    end

    test "run/2 runs the command" do
      cmd = %Command{foo: "bar"}

      assert :ok = Command.run(cmd)
    end

    test "execute/2 inits, validates and runs a command all at once" do
      attrs = %{"foo" => "bar"}

      assert :ok = Command.execute(attrs)
    end
  end
end
