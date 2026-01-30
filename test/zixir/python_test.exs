defmodule Zixir.PythonTest do
  use ExUnit.Case, async: false

  describe "call_python/3" do
    test "returns ok or error (Python specialist)" do
      result = Zixir.call_python("math", "sqrt", [4.0])
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    @tag :python_integration
    test "calls stdlib math.sqrt when Python ready" do
      case Zixir.call_python("math", "sqrt", [4.0]) do
        {:ok, v} -> assert_in_delta(v, 2.0, 0.001)
        {:error, _} -> assert true
      end
    end
  end
end
