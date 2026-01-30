defmodule Zixir.Intent do
  @moduledoc """
  Intent / task router: routes calls to Zig (engine) or Python (specialist).
  Hot path (math, data) → Zig; library calls → Python.
  """

  use GenServer

  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @doc """
  Run engine (Zig) operation. `op` is an atom (e.g. `:list_sum`, `:blas_axpy`); `args` is a list.
  """
  def run_engine(op, args) when is_atom(op) and is_list(args) do
    Zixir.Engine.run(op, args)
  end

  @doc """
  Call Python specialist: module, function, args. Returns `{:ok, result}` or `{:error, reason}`.
  """
  def call_python(module, function, args)
      when (is_binary(module) or is_atom(module)) and
             (is_binary(function) or is_atom(function)) and
             is_list(args) do
    Zixir.Python.call(module, function, args)
  end

  def call_python(_module, _function, _args), do: {:error, :invalid_args}
end
