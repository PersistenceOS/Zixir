defmodule Zixir.CLI do
  @moduledoc """
  Portable CLI entry point for releases.
  Run a .zixir file by path from any working directory.

  Used by the release overlay scripts (zixir_run) and by:
  bin/zixir eval "Zixir.CLI.run_file(Path.expand(\\\"path/to/file.zixir\\\"))"
  or with argv: bin/zixir eval "Zixir.CLI.run_file_from_argv()" -- /path/to/file.zixir
  """

  @doc """
  Run a file using the first non-\"--\" argument from System.argv().
  Used by release scripts so the path is not confused with the eval \"--\" separator.
  """
  def run_file_from_argv do
    path = System.argv() |> Enum.reject(&(&1 == "--")) |> List.first()
    if path in [nil, ""] do
      IO.puts(:stderr, "zixir: usage: zixir_run <path/to/file.zixir>")
      System.halt(1)
    else
      run_file(path)
    end
  end

  @doc """
  Read, evaluate, and print the result of a Zixir source file.
  Path can be absolute or relative to the current working directory.
  Exits the VM with code 0 on success, 1 on error (for use from scripts).
  """
  def run_file(path) when is_binary(path) do
    _ = Application.ensure_all_started(:zixir)
    expanded = Path.expand(path)

    cond do
      not File.exists?(expanded) ->
        IO.puts(:stderr, "zixir: file not found: #{expanded}")
        System.halt(1)

      true ->
        source = File.read!(expanded)

        case Zixir.eval(source) do
          {:ok, result} ->
            IO.puts(inspect(result))
            System.halt(0)

          {:error, %Zixir.CompileError{message: msg, line: line, column: col}} ->
            IO.puts(:stderr, "zixir: #{expanded}#{location(line, col)}: #{msg}")
            System.halt(1)

          {:error, reason} ->
            IO.puts(:stderr, "zixir: #{expanded}: #{inspect(reason)}")
            System.halt(1)
        end
    end
  end

  defp location(nil, _), do: ""
  defp location(line, nil), do: ":#{line}"
  defp location(line, col), do: ":#{line}:#{col}"
end
