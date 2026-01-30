defmodule Zixir.Compiler.ParserTest do
  use ExUnit.Case, async: true

  describe "Phase 1: Parser" do
    test "parses number literals" do
      assert {:ok, {:program, [{:number, 42, 1, 1}]}} = Zixir.Compiler.Parser.parse("42")
      assert {:ok, {:program, [{:number, 3.14, 1, 1}]}} = Zixir.Compiler.Parser.parse("3.14")
    end

    test "parses string literals" do
      assert {:ok, {:program, [{:string, "hello", 1, 1}]}} = Zixir.Compiler.Parser.parse("\"hello\"")
    end

    test "parses boolean literals" do
      assert {:ok, {:program, [{:bool, true, 1, 1}]}} = Zixir.Compiler.Parser.parse("true")
      assert {:ok, {:program, [{:bool, false, 1, 1}]}} = Zixir.Compiler.Parser.parse("false")
    end

    test "parses variable references" do
      assert {:ok, {:program, [{:var, "x", 1, 1}]}} = Zixir.Compiler.Parser.parse("x")
    end

    test "parses binary operations" do
      {:ok, ast} = Zixir.Compiler.Parser.parse("1 + 2")
      assert {:program, [{:binop, :add, {:number, 1, _, _}, {:number, 2, _, _}}]} = ast
    end

    test "parses let bindings" do
      {:ok, ast} = Zixir.Compiler.Parser.parse("let x = 5")
      assert {:program, [{:let, "x", {:number, 5, _, _}, 1, 1}]} = ast
    end

    test "parses function definitions" do
      {:ok, ast} = Zixir.Compiler.Parser.parse("fn add(x: Int, y: Int) -> Int: x + y")
      assert {:program, [{:function, "add", [{"x", {:type, :Int}}, {"y", {:type, :Int}}], {:type, :Int}, _, false, 1, 1}]} = ast
    end

    test "parses arrays" do
      {:ok, ast} = Zixir.Compiler.Parser.parse("[1, 2, 3]")
      assert {:program, [{:array, [{:number, 1, _, _}, {:number, 2, _, _}, {:number, 3, _, _}], 1, 1}]} = ast
    end

    test "parses if expressions" do
      {:ok, ast} = Zixir.Compiler.Parser.parse("if x: y else: z")
      assert {:program, [{:if, {:var, "x", _, _}, {:var, "y", _, _}, {:var, "z", _, _}, 1, 1}]} = ast
    end

    test "handles parse errors gracefully" do
      assert {:error, %Zixir.Compiler.Parser.ParseError{}} = Zixir.Compiler.Parser.parse("let x = ")
    end
  end
end
