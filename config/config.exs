import Config

config :zixir,
  python_path: System.find_executable("python3") || System.find_executable("python"),
  python_workers_max: 4,
  restart_window_seconds: 5,
  max_restarts: 3

if config_env() == :test do
  config :zixir,
    python_workers_max: 1
end
