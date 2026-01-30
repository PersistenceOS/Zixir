defmodule Zixir.MLIR do
  @moduledoc """
  Optional MLIR layer: Elixir DSL to build MLIR IR; execute via Beaver or lower to Zig engine.

  To enable: add `{:beaver, "~> 0.4"}` to your deps (remove optional: true if you need MLIR).
  Use for math/kernel optimization and future language front-end.
  Orchestration is expressed in Elixir (pseudo-code/LLM-friendly); avoid hardcoded JSON for flow.
  """

  @doc """
  Build MLIR from a creator function (when Beaver is available).
  Creator receives MLIR context; returns module or IR to execute/lower.
  Returns `{:ok, result}` when Beaver is loaded and execution succeeds; `{:error, :beaver_not_available}` otherwise.
  When Beaver is in deps, use Beaver.MLIR and Beaver.MLIR.ExecutionEngine directly; this stub returns :beaver_not_available until wired.
  """
  def build_and_run(creator) when is_function(creator, 1) do
    case ensure_beaver() do
      :ok -> run_creator(creator)
      err -> err
    end
  end

  def build_and_run(_), do: {:error, :invalid_creator}

  defp ensure_beaver() do
    if Code.ensure_loaded?(Beaver) and function_exported?(Beaver, :__info__, 1) do
      :ok
    else
      {:error, :beaver_not_available}
    end
  end

  defp run_creator(_creator) do
    {:error, :beaver_not_available}
  end
end
