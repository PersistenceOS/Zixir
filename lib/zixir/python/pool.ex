defmodule Zixir.Python.Pool do
  @moduledoc """
  Pool of Python port workers. Dispatches calls to available workers; returns structured errors when down.
  Consults circuit breaker before calling; records success/failure after call.
  """

  def call(module, function, args) do
    case Zixir.Python.CircuitBreaker.allow?() do
      :ok ->
        case Zixir.Python.WorkerPool.get_worker() do
          {:ok, pid} ->
            result = Zixir.Python.Worker.call(pid, module, function, args)
            case result do
              {:ok, _} -> Zixir.Python.CircuitBreaker.record_success()
              {:error, _} -> Zixir.Python.CircuitBreaker.record_failure()
            end
            result
          {:error, _} = err ->
            Zixir.Python.CircuitBreaker.record_failure()
            err
        end
      {:error, :circuit_open} ->
        {:error, :circuit_open}
    end
  end
end
