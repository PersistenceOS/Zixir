defmodule Zixir.Engine.Math do
  @moduledoc """
  Zig engine NIFs: math and buffer ops. Uses Zigler BEAM allocator.
  Keep NIFs short (< 1ms); use dirty CPU only when needed.
  
  Provides graceful fallbacks to pure Elixir when NIFs are not available.
  """

  use Zig, otp_app: :zixir

  ~Z"""
  /// Sum of f64 list. BEAM allocator used if Zig allocates.
  pub fn list_sum(array: []const f64) f64 {
    var sum: f64 = 0.0;
    for (array) |item| {
      sum += item;
    }
    return sum;
  }

  /// Product of f64 list.
  pub fn list_product(array: []const f64) f64 {
    var prod: f64 = 1.0;
    for (array) |item| {
      prod *= item;
    }
    return prod;
  }

  /// Dot product of two f64 slices. Returns 0.0 if lengths differ.
  pub fn dot_product(a: []const f64, b: []const f64) f64 {
    if (a.len != b.len) return 0.0;
    var sum: f64 = 0.0;
    for (a, b) |x, y| {
      sum += x * y;
    }
    return sum;
  }

  /// Byte length of binary. No allocation.
  pub fn string_count(string: []const u8) i64 {
    return @intCast(string.len);
  }
  """

  @doc """
  Check if NIFs are loaded and available.
  """
  def nifs_available? do
    # Try to call a simple NIF function to check if they're loaded
    try do
      _ = list_sum([])
      true
    rescue
      _ -> false
    end
  end

  @doc """
  Sum of f64 list. Uses NIF if available, falls back to Elixir implementation.
  """
  def list_sum_safe(array) when is_list(array) do
    if nifs_available?() do
      list_sum(array)
    else
      Enum.sum(array)
    end
  end

  @doc """
  Product of f64 list. Uses NIF if available, falls back to Elixir implementation.
  """
  def list_product_safe(array) when is_list(array) do
    if nifs_available?() do
      list_product(array)
    else
      Enum.product(array)
    end
  end

  @doc """
  Dot product of two f64 lists. Uses NIF if available, falls back to Elixir implementation.
  """
  def dot_product_safe(a, b) when is_list(a) and is_list(b) do
    if nifs_available?() do
      dot_product(a, b)
    else
      if length(a) != length(b) do
        0.0
      else
        Enum.zip(a, b)
        |> Enum.reduce(0.0, fn {x, y}, acc -> acc + x * y end)
      end
    end
  end

  @doc """
  Byte length of binary. Uses NIF if available, falls back to Elixir implementation.
  """
  def string_count_safe(string) when is_binary(string) do
    if nifs_available?() do
      string_count(string)
    else
      byte_size(string)
    end
  end
end
