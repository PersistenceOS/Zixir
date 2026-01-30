defmodule Zixir.Python.Supervisor do
  @moduledoc """
  Supervises Python port workers. Each worker is a supervised port process.
  Restart limits applied by parent supervisor.
  """

  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    max = Application.get_env(:zixir, :python_workers_max, 4)

    children =
      for i <- 0..(max - 1) do
        Supervisor.child_spec(
          {Zixir.Python.Worker, [id: i]},
          id: {Zixir.Python.Worker, i}
        )
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
