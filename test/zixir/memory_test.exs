defmodule Zixir.MemoryTest do
  use ExUnit.Case, async: false

  alias Zixir.Memory

  setup do
    # Ensure the Memory GenServer is started
    case Process.whereis(Memory) do
      nil ->
        start_supervised!(Zixir.Memory)
      _pid ->
        :ok
    end

    # Clean up after each test
    on_exit(fn ->
      # Clear all keys
      :sys.replace_state(Memory, fn _state -> %{} end)
    end)

    :ok
  end

  describe "put/2 and get/1" do
    test "stores and retrieves values" do
      assert :ok = Memory.put(:key1, "value1")
      assert {:ok, "value1"} = Memory.get(:key1)
    end

    test "stores different types" do
      assert :ok = Memory.put(:string, "hello")
      assert :ok = Memory.put(:number, 42)
      assert :ok = Memory.put(:float, 3.14)
      assert :ok = Memory.put(:list, [1, 2, 3])
      assert :ok = Memory.put(:map, %{a: 1, b: 2})
      assert :ok = Memory.put(:tuple, {:ok, "result"})

      assert {:ok, "hello"} = Memory.get(:string)
      assert {:ok, 42} = Memory.get(:number)
      assert {:ok, 3.14} = Memory.get(:float)
      assert {:ok, [1, 2, 3]} = Memory.get(:list)
      assert {:ok, %{a: 1, b: 2}} = Memory.get(:map)
      assert {:ok, {:ok, "result"}} = Memory.get(:tuple)
    end

    test "returns :error for non-existent keys" do
      assert :error = Memory.get(:non_existent_key)
    end

    test "overwrites existing values" do
      assert :ok = Memory.put(:key, "original")
      assert {:ok, "original"} = Memory.get(:key)

      assert :ok = Memory.put(:key, "updated")
      assert {:ok, "updated"} = Memory.get(:key)
    end

    test "handles complex nested data" do
      complex_data = %{
        users: [
          %{name: "Alice", age: 30},
          %{name: "Bob", age: 25}
        ],
        metadata: %{
          total: 2,
          page: 1
        }
      }

      assert :ok = Memory.put(:complex, complex_data)
      assert {:ok, ^complex_data} = Memory.get(:complex)
    end
  end

  describe "delete/1" do
    test "removes a key" do
      assert :ok = Memory.put(:to_delete, "value")
      assert {:ok, "value"} = Memory.get(:to_delete)

      assert :ok = Memory.delete(:to_delete)
      assert :error = Memory.get(:to_delete)
    end

    test "returns :ok for non-existent keys" do
      assert :ok = Memory.delete(:never_existed)
    end
  end

  describe "concurrent access" do
    test "handles concurrent writes" do
      tasks = for i <- 1..10 do
        Task.async(fn ->
          Memory.put("key_#{i}", "value_#{i}")
        end)
      end

      results = Task.await_many(tasks)
      assert Enum.all?(results, fn result -> result == :ok end)

      for i <- 1..10 do
        expected_value = "value_#{i}"
        assert {:ok, ^expected_value} = Memory.get("key_#{i}")
      end
    end

    test "handles concurrent reads and writes" do
      # Pre-populate
      for i <- 1..5 do
        Memory.put("key_#{i}", i * 10)
      end

      tasks = for i <- 1..20 do
        Task.async(fn ->
          if rem(i, 2) == 0 do
            Memory.put("key_#{rem(i, 5) + 1}", i)
          else
            Memory.get("key_#{rem(i, 5) + 1}")
          end
        end)
      end

      results = Task.await_many(tasks)
      # All operations should complete without crashing
      assert length(results) == 20
    end
  end

  describe "edge cases" do
    test "handles nil values" do
      assert :ok = Memory.put(:nil_key, nil)
      assert {:ok, nil} = Memory.get(:nil_key)
    end

    test "handles empty strings" do
      assert :ok = Memory.put(:empty, "")
      assert {:ok, ""} = Memory.get(:empty)
    end

    test "handles empty collections" do
      assert :ok = Memory.put(:empty_list, [])
      assert :ok = Memory.put(:empty_map, %{})

      assert {:ok, []} = Memory.get(:empty_list)
      assert {:ok, %{}} = Memory.get(:empty_map)
    end

    test "handles binary keys" do
      assert :ok = Memory.put(<<1, 2, 3>>, "binary_key")
      assert {:ok, "binary_key"} = Memory.get(<<1, 2, 3>>)
    end
  end
end
