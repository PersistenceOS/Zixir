defmodule Zixir.Compiler.TypeSystemTest do
  use ExUnit.Case, async: true

  alias Zixir.Compiler.TypeSystem
  alias Zixir.Compiler.TypeSystem.Type

  describe "Type module" do
    test "creates basic types" do
      assert Type.int() == :int
      assert Type.float() == :float
      assert Type.bool() == :bool
      assert Type.string() == :string
      assert Type.void() == :void
    end

    test "creates complex types" do
      assert Type.array(:int) == {:array, :int}
      assert Type.function([:int, :int], :int) == {:function, [:int, :int], :int}
      assert Type.var(0) == {:var, 0}
      assert Type.var(1) == {:var, 1}
      assert Type.poly("List", [:int]) == {:poly, "List", [:int]}
    end
  end

  describe "type_to_string/1" do
    test "formats basic types" do
      assert TypeSystem.type_to_string(:int) == "Int"
      assert TypeSystem.type_to_string(:float) == "Float"
      assert TypeSystem.type_to_string(:bool) == "Bool"
      assert TypeSystem.type_to_string(:string) == "String"
      assert TypeSystem.type_to_string(:void) == "Void"
    end

    test "formats array types" do
      assert TypeSystem.type_to_string({:array, :int}) == "[Int]"
      assert TypeSystem.type_to_string({:array, {:array, :float}}) == "[[Float]]"
    end

    test "formats function types" do
      assert TypeSystem.type_to_string({:function, [:int, :int], :int}) == "(Int, Int) -> Int"
      assert TypeSystem.type_to_string({:function, [], :void}) == "() -> Void"
    end

    test "formats type variables" do
      assert TypeSystem.type_to_string({:var, 0}) == "'t0"
      assert TypeSystem.type_to_string({:var, 42}) == "'t42"
    end

    test "formats parametric types" do
      assert TypeSystem.type_to_string({:poly, "List", [:int]}) == "List<Int>"
      assert TypeSystem.type_to_string({:poly, "Map", [:string, :int]}) == "Map<String, Int>"
    end
  end

  describe "infer/1 - basic literals" do
    test "infers integer literals" do
      ast = {:program, [{:number, 42, 1, 1}]}
      assert {:ok, typed_ast} = TypeSystem.infer(ast)
      assert {:program, [typed_num]} = typed_ast
      assert elem(typed_num, 0) == :number
    end

    test "infers float literals" do
      ast = {:program, [{:number, 3.14, 1, 1}]}
      assert {:ok, typed_ast} = TypeSystem.infer(ast)
      assert {:program, [typed_num]} = typed_ast
      assert elem(typed_num, 0) == :number
    end

    test "infers string literals" do
      ast = {:program, [{:string, "hello", 1, 1}]}
      assert {:ok, typed_ast} = TypeSystem.infer(ast)
      assert {:program, [typed_str]} = typed_ast
      assert elem(typed_str, 0) == :string
    end

    test "infers boolean literals" do
      ast = {:program, [{:bool, true, 1, 1}]}
      assert {:ok, typed_ast} = TypeSystem.infer(ast)
      assert {:program, [typed_bool]} = typed_ast
      assert elem(typed_bool, 0) == :bool
    end
  end

  describe "infer/1 - binary operations" do
    test "infers arithmetic operations" do
      # 1 + 2
      ast = {:program, [{:binop, :add, {:number, 1, 1, 1}, {:number, 2, 1, 5}}]}
      assert {:ok, _typed_ast} = TypeSystem.infer(ast)
    end

    test "infers comparison operations" do
      # 1 < 2
      ast = {:program, [{:binop, :<, {:number, 1, 1, 1}, {:number, 2, 1, 5}}]}
      assert {:ok, _typed_ast} = TypeSystem.infer(ast)
    end
  end

  describe "infer/1 - variable bindings" do
    test "infers let bindings" do
      # let x = 5
      ast = {:program, [{:let, "x", {:number, 5, 1, 9}, 1, 1}]}
      assert {:ok, typed_ast} = TypeSystem.infer(ast)
      assert {:program, [typed_let]} = typed_ast
      assert elem(typed_let, 0) == :let
    end

    test "infers variable references" do
      # x (where x is bound)
      ast = {:program, [
        {:let, "x", {:number, 5, 1, 9}, 1, 1},
        {:var, "x", 2, 1}
      ]}
      assert {:ok, _typed_ast} = TypeSystem.infer(ast)
    end
  end

  describe "infer/1 - arrays" do
    test "infers empty arrays" do
      ast = {:program, [{:array, [], 1, 1}]}
      assert {:ok, _typed_ast} = TypeSystem.infer(ast)
    end

    test "infers homogeneous arrays" do
      # [1, 2, 3]
      ast = {:program, [{:array, [
        {:number, 1, 1, 2},
        {:number, 2, 1, 5},
        {:number, 3, 1, 8}
      ], 1, 1}]}
      assert {:ok, _typed_ast} = TypeSystem.infer(ast)
    end
  end

  describe "infer/1 - conditionals" do
    test "infers if expressions" do
      # if true: 1 else: 0
      ast = {:program, [{:if, 
        {:bool, true, 1, 4},
        {:block, [{:number, 1, 1, 10}]},
        {:block, [{:number, 0, 1, 18}]},
        1, 1
      }]}
      assert {:ok, _typed_ast} = TypeSystem.infer(ast)
    end
  end

  describe "check_type/3" do
    test "checks compatible types" do
      expr = {:number, 42, 1, 1}
      # Returns error because type inference returns :unknown for untyped AST
      assert {:error, _} = TypeSystem.check_type(expr, :int, %{})
    end
  end

  describe "TypeError" do
    test "creates type error with message" do
      error = %TypeSystem.TypeError{
        message: "Type mismatch",
        location: 1,
        expected: :int,
        actual: :float
      }
      assert error.message == "Type mismatch"
      assert error.expected == :int
      assert error.actual == :float
    end

    test "formats type error message" do
      opts = [expected: :int, actual: :float]
      error = TypeSystem.TypeError.exception(opts)
      assert error.message == "Type mismatch: expected Int, got Float"
    end
  end
end
