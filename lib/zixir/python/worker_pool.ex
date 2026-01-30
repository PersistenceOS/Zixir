defmodule Zixir.Python.WorkerPool do
  @moduledoc """
  Simple worker pool: returns a registered Python worker PID for the Pool to use.
  """

  def get_worker() do
    # Registry entries are {key, pid, value}; capture pid (second element).
    pids = Registry.select(Zixir.Python.Registry, [{{:_, :"$1", :_}, [], [:"$1"]}])
    case pids do
      [] -> {:error, :no_workers}
      [pid | _] -> {:ok, pid}
    end
  end
end
