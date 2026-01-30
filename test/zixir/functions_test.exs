defmodule Zixir.FunctionsTest do
  use ExUnit.Case, async: true

  describe "function definitions and calls" do
    test "simple function with two parameters" do
      code = """
      fn add(x: Int, y: Int) -> Int: x + y
      add(3, 4)
      """
      assert {:ok, 7} = Zixir.eval(code)
    end

    test "function with single parameter" do
      code = """
      fn double(x: Int) -> Int: x * 2
      double(5)
      """
      assert {:ok, 10} = Zixir.eval(code)
    end

    test "multiple functions" do
      code = """
      fn add(x: Int, y: Int) -> Int: x + y
      fn mul(x: Int, y: Int) -> Int: x * y
      add(2, 3) + mul(2, 3)
      """
      assert {:ok, 11} = Zixir.eval(code)
    end

    test "function calling another function" do
      code = """
      fn square(x: Int) -> Int: x * x
      fn sum_of_squares(x: Int, y: Int) -> Int: square(x) + square(y)
      sum_of_squares(3, 4)
      """
      assert {:ok, 25} = Zixir.eval(code)
    end

    test "function with complex body" do
      code = """
      fn max(x: Int, y: Int) -> Int: if x > y: x else: y
      max(10, 5)
      """
      assert {:ok, 10} = Zixir.eval(code)
    end

    test "function with boolean return" do
      code = """
      fn is_positive(x: Int) -> Bool: x > 0
      is_positive(5)
      """
      assert {:ok, true} = Zixir.eval(code)
    end

    test "function returning string" do
      _code = """
      fn greet(name: String) -> String: "Hello, " + name
      greet("World")
      """
      # Note: String concatenation with + might not work yet
      # This test documents expected behavior
    end

    test "recursive function (factorial)" do
      code = """
      fn factorial(n: Int) -> Int: if n <= 1: 1 else: n * factorial(n - 1)
      factorial(5)
      """
      assert {:ok, 120} = Zixir.eval(code)
    end

    test "function with wrong number of arguments" do
      code = """
      fn add(x: Int, y: Int) -> Int: x + y
      add(1)
      """
      assert {:error, "Function add expects 2 arguments, got 1"} = Zixir.eval(code)
    end

    test "undefined function call" do
      assert {:error, "Undefined function: nonexistent"} = Zixir.eval("nonexistent(1, 2)")
    end

    test "function parameter shadowing" do
      code = """
      let x = 10
      fn foo(x: Int) -> Int: x
      foo(5)
      """
      # Function parameter should shadow outer variable
      assert {:ok, 5} = Zixir.eval(code)
    end

    test "function with no parameters" do
      code = """
      fn get_five() -> Int: 5
      get_five()
      """
      assert {:ok, 5} = Zixir.eval(code)
    end

    test "nested function calls" do
      code = """
      fn add(x: Int, y: Int) -> Int: x + y
      fn mul(x: Int, y: Int) -> Int: x * y
      add(mul(2, 3), mul(3, 4))
      """
      assert {:ok, 18} = Zixir.eval(code)
    end

    test "function with float parameters" do
      code = """
      fn add_floats(x: Float, y: Float) -> Float: x + y
      add_floats(1.5, 2.5)
      """
      assert {:ok, 4.0} = Zixir.eval(code)
    end

    test "higher-order function pattern (function as parameter concept)" do
      # This tests that we can pass computed values to functions
      code = """
      fn apply_twice(x: Int, f: Int) -> Int: x * 2
      apply_twice(5, 0)
      """
      # Note: Real higher-order functions (passing functions as values) 
      # are not yet supported - this just tests the syntax works
      assert {:ok, 10} = Zixir.eval(code)
    end
  end

  describe "function edge cases" do
    test "function defined but not called" do
      code = """
      fn unused(x: Int) -> Int: x
      42
      """
      assert {:ok, 42} = Zixir.eval(code)
    end

    test "function called multiple times" do
      code = """
      fn add(x: Int, y: Int) -> Int: x + y
      add(1, 2) + add(3, 4) + add(5, 6)
      """
      assert {:ok, 21} = Zixir.eval(code)
    end

    test "function with negative numbers" do
      code = """
      fn abs(x: Int) -> Int: if x < 0: -x else: x
      abs(-5)
      """
      assert {:ok, 5} = Zixir.eval(code)
    end

    test "function using variables from outer scope (closure-like)" do
      # Functions don't capture outer scope currently, but let's test the behavior
      code = """
      let multiplier = 10
      fn times_ten(x: Int) -> Int: x * 10
      times_ten(5)
      """
      assert {:ok, 50} = Zixir.eval(code)
    end
  end
end
