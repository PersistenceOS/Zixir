defmodule Zixir.Python.Worker do
  @moduledoc """
  Single Python port worker. Supervised; on crash supervisor restarts it.
  Opens port to priv/python/port_bridge.py; sends/receives via Zixir.Python.Protocol.
  """

  use GenServer

  def start_link(opts \\ []) do
    id = Keyword.get(opts, :id, 0)
    GenServer.start_link(__MODULE__, opts, name: via(id))
  end

  def call(pid, module, function, args) when is_pid(pid) do
    GenServer.call(pid, {:call, module, function, args}, 30_000)
  end

  defp via(id), do: {:via, Registry, {Zixir.Python.Registry, id}}

  @impl true
  def init(opts) do
    id = Keyword.get(opts, :id, 0)
    port = start_port()
    state = %{id: id, port: port, pending: nil, buffer: ""}
    {:ok, state}
  end

  defp start_port() do
    python_path = Application.get_env(:zixir, :python_path) || System.find_executable("python3") || System.find_executable("python")
    script_path = script_path()

    if is_nil(python_path) or is_nil(script_path) do
      nil
    else
      Port.open({:spawn_executable, python_path}, [:binary, {:line, 4096}, :stderr_to_stdout, {:args, [script_path]}])
    end
  rescue
    _ -> nil
  end

  defp script_path() do
    base = Application.app_dir(:zixir)
    path = Path.join([base, "priv", "python", "port_bridge.py"])
    if File.exists?(path), do: path, else: nil
  end

  @impl true
  def handle_call({:call, _module, _function, _args}, _from, %{port: nil} = state) do
    {:reply, {:error, :python_not_ready}, state}
  end

  def handle_call({:call, module, function, args}, from, %{port: port, pending: nil} = state) do
    request = Zixir.Python.Protocol.encode_request(module, function, args)
    Port.command(port, request)
    {:noreply, %{state | pending: from}}
  end

  def handle_call({:call, _m, _f, _a}, _from, %{pending: _} = state) do
    {:reply, {:error, :busy}, state}
  end

  @impl true
  def handle_info({port, {:data, {:eol, line}}}, %{port: port, pending: from} = state) when not is_nil(from) do
    result = Zixir.Python.Protocol.decode_response(line)
    reply = case result do
      {:ok, value} -> {:ok, value}
      {:error, reason} -> {:error, reason}
    end
    GenServer.reply(from, reply)
    {:noreply, %{state | pending: nil}}
  end

  def handle_info({port, {:data, {:noeol, chunk}}}, %{port: port, buffer: buf} = state) do
    {:noreply, %{state | buffer: buf <> chunk}}
  end

  def handle_info({port, {:data, data}}, %{port: port} = state) when is_binary(data) do
    buf = state.buffer <> data
    case String.split(buf, "\n", parts: 2) do
      [line, rest] ->
        result = Zixir.Python.Protocol.decode_response(line)
        reply = case result do
          {:ok, value} -> {:ok, value}
          {:error, reason} -> {:error, reason}
        end
        if state.pending do
          GenServer.reply(state.pending, reply)
          {:noreply, %{state | pending: nil, buffer: rest}}
        else
          {:noreply, %{state | buffer: rest}}
        end
      [_] ->
        {:noreply, %{state | buffer: buf}}
    end
  end

  def handle_info({_port, {:exit_status, _status}}, state) do
    if state.pending do
      GenServer.reply(state.pending, {:error, :port_closed})
    end
    {:noreply, %{state | port: nil, pending: nil}}
  end

  def handle_info(_, state), do: {:noreply, state}
end
