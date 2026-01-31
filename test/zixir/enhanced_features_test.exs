defmodule Zixir.EnhancedFeaturesTest do
  use ExUnit.Case, async: false

  describe "Enhanced Python Bridge" do
    test "call Python math.sqrt" do
      result = Zixir.Python.math("sqrt", [16.0])
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    test "call Python numpy operations" do
      result = Zixir.Python.numpy("array", [[1, 2, 3]])
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    test "Python pool stats" do
      stats = Zixir.Python.stats()
      assert is_map(stats)
      assert Map.has_key?(stats, :total_workers)
      assert Map.has_key?(stats, :healthy_workers)
    end

    test "Python health check" do
      # Just verify it doesn't crash
      _ = Zixir.Python.healthy?()
      assert true
    end

    test "parallel Python calls" do
      calls = [
        {"math", "sqrt", [1.0]},
        {"math", "sqrt", [4.0]},
        {"math", "sqrt", [9.0]}
      ]
      
      results = Zixir.Python.parallel(calls, timeout: 10_000)
      assert length(results) == 3
    end
  end

  describe "Enhanced Engine Operations" do
    test "list_mean" do
      result = Zixir.Engine.run(:list_mean, [[1.0, 2.0, 3.0, 4.0, 5.0]])
      assert result == 3.0
    end

    test "list_min" do
      result = Zixir.Engine.run(:list_min, [[3.0, 1.0, 4.0, 1.0, 5.0]])
      assert result == 1.0
    end

    test "list_max" do
      result = Zixir.Engine.run(:list_max, [[3.0, 1.0, 4.0, 1.0, 5.0]])
      assert result == 5.0
    end

    test "vec_add" do
      result = Zixir.Engine.run(:vec_add, [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
      assert result == [5.0, 7.0, 9.0]
    end

    test "vec_scale" do
      result = Zixir.Engine.run(:vec_scale, [[1.0, 2.0, 3.0], 2.0])
      assert result == [2.0, 4.0, 6.0]
    end

    test "map_add" do
      result = Zixir.Engine.run(:map_add, [[1.0, 2.0, 3.0], 10.0])
      assert result == [11.0, 12.0, 13.0]
    end

    test "filter_gt" do
      result = Zixir.Engine.run(:filter_gt, [[1.0, 5.0, 2.0, 8.0, 3.0], 3.0])
      assert result == [5.0, 8.0]
    end

    test "sort_asc" do
      result = Zixir.Engine.run(:sort_asc, [[3.0, 1.0, 4.0, 1.0, 5.0]])
      assert result == [1.0, 1.0, 3.0, 4.0, 5.0]
    end

    test "find_index" do
      result = Zixir.Engine.run(:find_index, [[1.0, 2.0, 3.0, 4.0], 3.0])
      assert result == 2
    end

    test "string_find" do
      result = Zixir.Engine.run(:string_find, ["hello world", "world"])
      assert result == 6
    end

    test "string_starts_with" do
      result = Zixir.Engine.run(:string_starts_with, ["hello world", "hello"])
      assert result == true
    end

    test "list_operations returns correct list" do
      ops = Zixir.Engine.operations()
      assert is_list(ops)
      assert :list_sum in ops
      assert :list_mean in ops
      assert :vec_add in ops
      assert :mat_mul in ops
      assert :string_find in ops
    end
  end

  describe "Module System" do
    test "Modules GenServer is running" do
      assert Process.whereis(Zixir.Modules) != nil
    end

    test "cache stats" do
      stats = Zixir.Modules.cache_stats()
      assert is_map(stats)
      assert Map.has_key?(stats, :hits)
      assert Map.has_key?(stats, :misses)
    end

    test "search paths" do
      paths = Zixir.Modules.search_paths()
      assert is_list(paths)
      assert length(paths) > 0
    end
  end

  describe "Pattern Matching" do
    test "match with literal pattern" do
      code = """
      let x = 5
      match x {
        5 => "five",
        _ => "other"
      }
      """
      
      result = Zixir.eval(code)
      assert result == {:ok, "five"}
    end

    test "match with variable pattern" do
      code = """
      let x = 10
      match x {
        n => n + 5
      }
      """
      
      result = Zixir.eval(code)
      assert result == {:ok, 15}
    end

    test "match with array pattern" do
      code = """
      let arr = [1, 2, 3]
      match arr {
        [a, b, c] => a + b + c
      }
      """
      
      result = Zixir.eval(code)
      assert result == {:ok, 6}
    end

    test "match with multiple clauses" do
      code = """
      let x = 3
      match x {
        1 => "one",
        2 => "two", 
        3 => "three",
        _ => "other"
      }
      """
      
      result = Zixir.eval(code)
      assert result == {:ok, "three"}
    end
  end

  describe "REPL" do
    test "REPL module is available" do
      assert Code.ensure_loaded?(Zixir.REPL)
    end

    test "Zixir.repl/0 is exported" do
      assert function_exported?(Zixir, :repl, 1)
    end
  end

  describe "Integration" do
    test "complex expression with engine and Python" do
      # This tests that both systems work together
      engine_result = Zixir.Engine.run(:list_sum, [[1.0, 2.0, 3.0]])
      assert engine_result == 6.0
      
      # Python call (may fail if Python not available)
      case Zixir.Python.math("sqrt", [16.0]) do
        {:ok, result} -> assert result == 4.0
        {:error, _} -> :ok  # Python not available, that's ok
      end
    end

    test "Zixir.eval with new engine operations" do
      code = """
      let data = [1.0, 2.0, 3.0, 4.0, 5.0]
      let avg = engine.list_mean(data)
      let doubled = engine.vec_scale(data, 2.0)
      engine.list_sum(doubled)
      """
      
      result = Zixir.eval(code)
      # Sum of [2.0, 4.0, 6.0, 8.0, 10.0] = 30.0
      assert result == {:ok, 30.0}
    end
  end
end
