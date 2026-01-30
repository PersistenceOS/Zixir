defmodule Zixir.LanguageTest do
  use ExUnit.Case, async: true

  describe "Zixir.eval/1" do
    test "number literal" do
      assert {:ok, 42} == Zixir.eval("42")
      assert {:ok, 3.14} == Zixir.eval("3.14")
    end

    test "engine.list_sum" do
      assert {:ok, 6.0} == Zixir.eval("engine.list_sum([1.0, 2.0, 3.0])")
      assert {:ok, 0.0} == Zixir.eval("engine.list_sum([])")
    end

    test "engine.string_count" do
      assert {:ok, 5} == Zixir.eval("engine.string_count(\"hello\")")
    end

    test "engine.list_product" do
      assert {:ok, 24.0} == Zixir.eval("engine.list_product([2.0, 3.0, 4.0])")
      assert {:ok, 1.0} == Zixir.eval("engine.list_product([])")
    end

    test "engine.dot_product" do
      assert {:ok, 32.0} == Zixir.eval("engine.dot_product([1.0, 2.0, 3.0], [4.0, 5.0, 6.0])")
    end

    test "let and var" do
      assert {:ok, 10} == Zixir.eval("let x = 5\nlet y = 5\nx + y")
    end

    test "binary ops" do
      assert {:ok, 15} == Zixir.eval("10 + 5")
      assert {:ok, 5} == Zixir.eval("10 - 5")
      assert {:ok, 50} == Zixir.eval("10 * 5")
      assert {:ok, 2.0} == Zixir.eval("10 / 5")
    end

    test "parse error returns CompileError" do
      assert {:error, %Zixir.CompileError{}} = Zixir.eval("let x = ")
    end
  end

  describe "Zixir.run/1" do
    test "returns value" do
      assert 6.0 == Zixir.run("engine.list_sum([1.0, 2.0, 3.0])")
    end

    test "raises on parse error" do
      assert_raise Zixir.CompileError, fn ->
        Zixir.run("syntax error [")
      end
    end
  end
end
