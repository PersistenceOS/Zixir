defmodule Zixir.ValidationTest do
  use ExUnit.Case, async: true

  describe "Basic Zixir Program Parsing" do
    test "parses a simple integer literal" do
      result = Zixir.Compiler.Parser.parse("42")
      assert {:ok, {:program, [{:number, 42, 1, 1}]}} = result
    end

    test "parses a simple string literal" do
      result = Zixir.Compiler.Parser.parse("\"hello\"")
      assert {:ok, {:program, [{:string, "hello", 1, 1}]}} = result
    end

    test "parses a simple boolean" do
      result = Zixir.Compiler.Parser.parse("true")
      assert {:ok, {:program, [{:bool, true, 1, 1}]}} = result
    end

    test "parses a variable reference" do
      result = Zixir.Compiler.Parser.parse("x")
      assert {:ok, {:program, [{:var, "x", 1, 1}]}} = result
    end

    test "parses a simple binary operation" do
      result = Zixir.Compiler.Parser.parse("1 + 2")
      assert {:ok, {:program, [{:binop, :add, {:number, 1, _, _}, {:number, 2, _, _}}]}} = result
    end

    test "parses a let binding" do
      result = Zixir.Compiler.Parser.parse("let x = 5")
      assert {:ok, {:program, [{:let, "x", {:number, 5, _, _}, 1, 1}]}} = result
    end

    test "parses an array literal" do
      result = Zixir.Compiler.Parser.parse("[1, 2, 3]")
      assert {:ok, {:program, [{:array, [{:number, 1, _, _}, {:number, 2, _, _}, {:number, 3, _, _}], 1, 1}]}} = result
    end

    test "returns error for invalid syntax" do
      result = Zixir.Compiler.Parser.parse("let x =")
      assert {:error, %Zixir.Compiler.Parser.ParseError{}} = result
    end
  end
end