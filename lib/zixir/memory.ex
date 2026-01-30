defmodule Zixir.Memory do
  @moduledoc """
  State / memory layer for agentic use: minimal human intervention, high success rate.
  In-memory cache keyed by term; supervised so it can be restarted cleanly.
  """

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @doc """
  Put a value under key. Keys and values are arbitrary Elixir terms.
  """
  def put(key, value) do
    GenServer.call(__MODULE__, {:put, key, value})
  end

  @doc """
  Get value for key. Returns `{:ok, value}` or `:error`.
  """
  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  @doc """
  Delete key. Returns `:ok`.
  """
  def delete(key) do
    GenServer.call(__MODULE__, {:delete, key})
  end

  @impl true
  def handle_call({:put, key, value}, _from, state) do
    {:reply, :ok, Map.put(state, key, value)}
  end

  def handle_call({:get, key}, _from, state) do
    case Map.fetch(state, key) do
      :error -> {:reply, :error, state}
      {:ok, v} -> {:reply, {:ok, v}, state}
    end
  end

  def handle_call({:delete, key}, _from, state) do
    {:reply, :ok, Map.delete(state, key)}
  end
end
