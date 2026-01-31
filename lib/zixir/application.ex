defmodule Zixir.Application do
  @moduledoc """
  Application and top-level supervision tree for Zixir.
  All long-lived components (intent router, memory, Python port workers) run under this supervisor.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Zixir.Python.Registry},
      Zixir.Memory,
      Zixir.Python.CircuitBreaker,
      Zixir.Python.Supervisor,
      Zixir.Modules,
      Zixir.Intent
    ]

    opts = [
      strategy: :rest_for_one,
      max_restarts: Application.get_env(:zixir, :max_restarts, 3),
      max_seconds: Application.get_env(:zixir, :restart_window_seconds, 5)
    ]

    Supervisor.start_link(children, opts)
  end
end
