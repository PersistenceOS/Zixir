defmodule Zixir.Python do
  @moduledoc """
  Enhanced Python specialist interface.
  
  Provides:
  - Basic library calls with automatic retries
  - Parallel batch execution
  - Type conversion helpers
  - Numpy/Pandas integration
  - Health monitoring
  
  ## Examples
  
      # Basic call
      Zixir.Python.call("math", "sqrt", [16.0])
      # => {:ok, 4.0}
      
      # With keyword arguments
      Zixir.Python.call("numpy", "array", [[1, 2, 3]], kwargs: [dtype: "float64"])
      
      # Pandas DataFrame
      Zixir.Python.call("pandas", "DataFrame", [], kwargs: [
        data: %{"A" => [1, 2, 3], "B" => [4, 5, 6]}
      ])
      
      # Parallel execution
      Zixir.Python.parallel([
        {"math", "sqrt", [1.0]},
        {"math", "sqrt", [4.0]},
        {"math", "sqrt", [9.0]}
      ])
  """

  @doc """
  Call Python function with automatic retries and circuit breaker protection.
  
  ## Options
  
    * `:timeout` - Call timeout in milliseconds (default: 30000)
    * `:kwargs` - Keyword arguments to pass to Python function
    * `:retries` - Number of retries on failure (default: 2)
  """
  def call(module, function, args, opts \\ []) do
    Zixir.Python.Pool.call(module, function, args, opts)
  end

  @doc """
  Call Python with expected return type conversion.
  """
  def call_with_type(module, function, args, expected_type, opts \\ []) do
    Zixir.Python.Pool.call_with_conversion(module, function, args, expected_type, opts)
  end

  @doc """
  Execute multiple Python calls in parallel.
  Returns list of results in same order as input.
  """
  def parallel(calls, opts \\ []) when is_list(calls) do
    Zixir.Python.Pool.parallel_calls(calls, opts)
  end

  @doc """
  Check if Python workers are healthy and ready.
  """
  def healthy?() do
    stats = Zixir.Python.Pool.stats()
    stats.healthy_workers > 0
  end

  @doc """
  Get pool statistics.
  """
  def stats() do
    Zixir.Python.Pool.stats()
  end

  @doc """
  Convenience function for numpy operations.
  """
  def numpy(function, args, opts \\ []) do
    call("numpy", function, args, opts)
  end

  @doc """
  Convenience function for pandas operations.
  """
  def pandas(function, args, opts \\ []) do
    call("pandas", function, args, opts)
  end

  @doc """
  Convenience function for math operations.
  """
  def math(function, args, opts \\ []) do
    call("math", function, args, opts)
  end

  @doc """
  Encode Elixir list as numpy array for efficient transfer.
  """
  def to_numpy_array(list, dtype \\ "f64") when is_list(list) do
    %{
      "__numpy_array__" => %{
        "dtype" => dtype,
        "shape" => [length(list)],
        "data" => encode_numeric_data(list, dtype)
      }
    }
  end

  @doc """
  Decode numpy array response to Elixir list.
  """
  def from_numpy_array(%{"__numpy_array__" => info}) do
    Zixir.Python.Protocol.decode_numpy_array(info)
  end

  def from_numpy_array(other), do: other

  # Helper functions
  defp encode_numeric_data(list, dtype) do
    data = case dtype do
      "f64" -> 
        Enum.map(list, &:erlang.float_to_binary(&1, [:native, :double])) |> IO.iodata_to_binary()
      "f32" -> 
        Enum.map(list, &:erlang.float_to_binary(&1, [:native, :float])) |> IO.iodata_to_binary()
      "i64" -> 
        Enum.map(list, &:erlang.term_to_binary(&1)) |> IO.iodata_to_binary()
      _ -> 
        :erlang.term_to_binary(list)
    end
    
    Base.encode64(data)
  end
end
