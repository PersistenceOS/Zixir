defmodule Zixir.Python do
  @moduledoc """
  Python specialist: port wrapper and protocol. Used only for library calls.
  """

  @doc """
  Call Python: module (binary or atom), function (binary or atom), args (list).
  Returns `{:ok, result}` or `{:error, reason}`. Uses supervised pool of port workers.
  """
  def call(module, function, args) do
    Zixir.Python.Pool.call(module, function, args)
  end
end
