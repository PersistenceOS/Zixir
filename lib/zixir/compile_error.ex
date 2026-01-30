defmodule Zixir.CompileError do
  @moduledoc """
  Compile-time error with Zixir source location (line/column) and message.
  """

  defexception [:message, :line, :column, :rest, :context]

  def message(%__MODULE__{message: msg, line: line, column: col})
      when is_integer(line) and is_integer(col) do
    "Zixir compile error at line #{line}, column #{col}: #{msg}"
  end

  def message(%__MODULE__{message: msg, rest: rest}) when is_binary(rest) and byte_size(rest) > 0 do
    preview = String.slice(rest, 0, 40) |> String.replace("\n", " ")
    "Zixir compile error: #{msg} (near: #{inspect(preview)})"
  end

  def message(%__MODULE__{message: msg}), do: "Zixir compile error: #{msg}"
end
