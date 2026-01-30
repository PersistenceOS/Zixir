defmodule Zixir.LanguageAdvancedTest do
  use ExUnit.Case, async: true

  describe "if/else expressions" do
    test "if with true condition" do
      assert {:ok, 10} = Zixir.eval("if true: 10")
    end

    test "if with false condition" do
      assert {:ok, nil} = Zixir.eval("if false: 10")
    end

    test "if/else with true condition" do
      assert {:ok, 10} = Zixir.eval("if true: 10 else: 20")
    end

    test "if/else with false condition" do
      assert {:ok, 20} = Zixir.eval("if false: 10 else: 20")
    end

    test "if with variable condition" do
      assert {:ok, 42} = Zixir.eval("let x = true\nif x: 42")
    end

    test "if with comparison" do
      assert {:ok, 1} = Zixir.eval("if 5 > 3: 1 else: 0")
      assert {:ok, 0} = Zixir.eval("if 3 > 5: 1 else: 0")
    end

    test "if with equality check" do
      assert {:ok, "yes"} = Zixir.eval("if 5 == 5: \"yes\" else: \"no\"")
      assert {:ok, "no"} = Zixir.eval("if 5 == 6: \"yes\" else: \"no\"")
    end

    test "nested if expressions" do
      code = """
      let x = 10
      if x > 5:
        if x < 15: "in range" else: "too high"
      else:
        "too low"
      """
      assert {:ok, "in range"} = Zixir.eval(code)
    end
  end

  describe "boolean operations" do
    test "and operation" do
      assert {:ok, true} = Zixir.eval("true && true")
      assert {:ok, false} = Zixir.eval("true && false")
      assert {:ok, false} = Zixir.eval("false && true")
      assert {:ok, false} = Zixir.eval("false && false")
    end

    test "or operation" do
      assert {:ok, true} = Zixir.eval("true || true")
      assert {:ok, true} = Zixir.eval("true || false")
      assert {:ok, true} = Zixir.eval("false || true")
      assert {:ok, false} = Zixir.eval("false || false")
    end

    test "not operation" do
      assert {:ok, false} = Zixir.eval("!true")
      assert {:ok, true} = Zixir.eval("!false")
    end

    test "combined boolean operations" do
      assert {:ok, true} = Zixir.eval("true && (false || true)")
      assert {:ok, false} = Zixir.eval("!true || false")
    end
  end

  describe "comparison operations" do
    test "less than" do
      assert {:ok, true} = Zixir.eval("3 < 5")
      assert {:ok, false} = Zixir.eval("5 < 3")
      assert {:ok, false} = Zixir.eval("5 < 5")
    end

    test "greater than" do
      assert {:ok, true} = Zixir.eval("5 > 3")
      assert {:ok, false} = Zixir.eval("3 > 5")
      assert {:ok, false} = Zixir.eval("5 > 5")
    end

    test "less than or equal" do
      assert {:ok, true} = Zixir.eval("3 <= 5")
      assert {:ok, true} = Zixir.eval("5 <= 5")
      assert {:ok, false} = Zixir.eval("6 <= 5")
    end

    test "greater than or equal" do
      assert {:ok, true} = Zixir.eval("5 >= 3")
      assert {:ok, true} = Zixir.eval("5 >= 5")
      assert {:ok, false} = Zixir.eval("3 >= 5")
    end

    test "not equal" do
      assert {:ok, true} = Zixir.eval("5 != 3")
      assert {:ok, false} = Zixir.eval("5 != 5")
    end
  end

  describe "variable scoping" do
    test "variables persist across statements" do
      code = """
      let x = 5
      let y = x + 3
      y
      """
      assert {:ok, 8} = Zixir.eval(code)
    end

    test "variable shadowing" do
      code = """
      let x = 5
      let x = 10
      x
      """
      assert {:ok, 10} = Zixir.eval(code)
    end

    test "multiple let bindings" do
      code = """
      let a = 1
      let b = 2
      let c = 3
      a + b + c
      """
      assert {:ok, 6} = Zixir.eval(code)
    end
  end

  describe "complex expressions" do
    test "arithmetic with variables" do
      code = """
      let x = 10
      let y = 3
      x * y + x / y
      """
      assert {:ok, 33.333333333333336} = Zixir.eval(code)
    end

    test "boolean with comparisons" do
      code = """
      let x = 5
      let y = 10
      x < y && y > 7
      """
      assert {:ok, true} = Zixir.eval(code)
    end

    test "complex conditional logic" do
      code = """
      let age = 25
      let is_adult = age >= 18
      let is_senior = age >= 65
      if is_adult && !is_senior: "adult" else: "other"
      """
      assert {:ok, "adult"} = Zixir.eval(code)
    end
  end

  describe "array operations" do
    test "empty array" do
      assert {:ok, []} = Zixir.eval("[]")
    end

    test "array with single element" do
      assert {:ok, [42]} = Zixir.eval("[42]")
    end

    test "array with multiple elements" do
      assert {:ok, [1, 2, 3]} = Zixir.eval("[1, 2, 3]")
    end

    test "array with mixed types (numbers)" do
      assert {:ok, [1, 2.5, 3]} = Zixir.eval("[1, 2.5, 3]")
    end

    test "array stored in variable" do
      code = """
      let arr = [1, 2, 3]
      arr
      """
      assert {:ok, [1, 2, 3]} = Zixir.eval(code)
    end

    test "array passed to engine function" do
      assert {:ok, 6.0} = Zixir.eval("engine.list_sum([1.0, 2.0, 3.0])")
      # Note: engine.list_sum with integers returns integer (6), with floats returns float (6.0)
      assert {:ok, 6} = Zixir.eval("engine.list_sum([1, 2, 3])")
    end
  end

  describe "string operations" do
    test "empty string" do
      assert {:ok, ""} = Zixir.eval("\"\"")
    end

    test "string with spaces" do
      assert {:ok, "hello world"} = Zixir.eval("\"hello world\"")
    end

    test "string stored in variable" do
      code = """
      let msg = "hello"
      msg
      """
      assert {:ok, "hello"} = Zixir.eval(code)
    end

    test "string passed to engine function" do
      assert {:ok, 5} = Zixir.eval("engine.string_count(\"hello\")")
      assert {:ok, 0} = Zixir.eval("engine.string_count(\"\")")
    end
  end

  describe "error handling" do
    test "undefined variable" do
      assert {:error, "Undefined variable: undefined_var"} = Zixir.eval("undefined_var")
    end

    test "undefined variable in expression" do
      assert {:error, "Undefined variable: x"} = Zixir.eval("x + 5")
    end

    test "division by zero" do
      assert {:error, "Division by zero"} = Zixir.eval("10 / 0")
    end

    test "unsupported expression returns error" do
      # This tests that we get a proper error for unimplemented features
      assert {:error, _} = Zixir.eval("fn add(x, y): x + y")
    end
  end

  describe "edge cases" do
    test "single number" do
      assert {:ok, 42} = Zixir.eval("42")
    end

    test "single boolean" do
      assert {:ok, true} = Zixir.eval("true")
      assert {:ok, false} = Zixir.eval("false")
    end

    test "single string" do
      assert {:ok, "test"} = Zixir.eval("\"test\"")
    end

    test "empty program" do
      assert {:ok, nil} = Zixir.eval("")
    end

    test "whitespace only" do
      assert {:ok, nil} = Zixir.eval("   \n\t  ")
    end

    test "comment only" do
      assert {:ok, nil} = Zixir.eval("# this is a comment")
    end

    test "program with comments" do
      code = """
      # Initialize x
      let x = 5
      # Add 3 to x
      x + 3
      """
      assert {:ok, 8} = Zixir.eval(code)
    end
  end
end
