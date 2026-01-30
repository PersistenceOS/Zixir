defmodule Zixir.EngineTest do
  use ExUnit.Case, async: true

  describe "run_engine/2" do
    test "list_sum" do
      assert Zixir.run_engine(:list_sum, [[1.0, 2.0, 3.0]]) == 6.0
      assert Zixir.run_engine(:list_sum, [[]]) == 0.0
    end

    test "string_count" do
      assert Zixir.run_engine(:string_count, ["hello zig"]) == 9
      assert Zixir.run_engine(:string_count, [""]) == 0
    end

    test "unknown op raises" do
      assert_raise ArgumentError, ~r/unknown engine op/, fn ->
        Zixir.run_engine(:unknown_op, [])
      end
    end
  end
end
