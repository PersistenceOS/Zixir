defmodule Zixir.Engine do
  @moduledoc """
  Elixir surface for Zig engine (NIFs via Zigler). No duplicate routing logic; Intent routes here for hot path.
  
  Provides graceful fallbacks to pure Elixir when Zig NIFs are not available.
  """

  require Logger

  @doc """
  Run engine operation. `op` is atom (e.g. :list_sum); `args` is list. 
  Returns result or raises on error.
  
  Automatically falls back to Elixir implementation if NIFs are not available.
  """
  def run(op, args) do
    try do
      do_run(op, args)
    rescue
      e in ErlangError ->
        # NIF not loaded, use fallback
        Logger.debug("NIF not available for #{op}, using Elixir fallback")
        run_fallback(op, args)
    end
  end

  defp do_run(op, args) do
    case op do
      :list_sum -> 
        Zixir.Engine.Math.list_sum(List.first(args) || [])
      :list_product -> 
        Zixir.Engine.Math.list_product(List.first(args) || [])
      :dot_product ->
        a = Enum.at(args, 0) || []
        b = Enum.at(args, 1) || []
        Zixir.Engine.Math.dot_product(a, b)
      :string_count -> 
        Zixir.Engine.Math.string_count(List.first(args) || "")
      _ -> 
        raise ArgumentError, "unknown engine op: #{inspect(op)}"
    end
  end

  defp run_fallback(op, args) do
    case op do
      :list_sum -> 
        Enum.sum(List.first(args) || [])
      :list_product -> 
        Enum.product(List.first(args) || [])
      :dot_product ->
        a = Enum.at(args, 0) || []
        b = Enum.at(args, 1) || []
        if length(a) != length(b), do: 0.0, else: Enum.zip(a, b) |> Enum.reduce(0.0, fn {x, y}, acc -> acc + x * y end)
      :string_count -> 
        byte_size(List.first(args) || "")
      _ -> 
        raise ArgumentError, "unknown engine op: #{inspect(op)}"
    end
  end

  @doc """
  Check if engine NIFs are available.
  """
  def nifs_available? do
    Zixir.Engine.Math.nifs_available?()
  end
end
