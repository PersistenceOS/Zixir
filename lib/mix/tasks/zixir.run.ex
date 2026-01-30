defmodule Mix.Tasks.Zixir.Run do
  @shortdoc "Run a .zixir source file"
  @moduledoc """
  Runs a Zixir source file.

      mix zixir.run path/to/file.zixir

  Parses, compiles, and evaluates the file; prints the result or raises on error.
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Application.ensure_all_started(:zixir)

    case args do
      [path | _] ->
        path = Path.expand(path)

        if File.exists?(path) do
          source = File.read!(path)

          case Zixir.eval(source) do
            {:ok, result} ->
              IO.puts(inspect(result))

            {:error, %Zixir.CompileError{} = e} ->
              Mix.raise(Exception.message(e))
          end
        else
          Mix.raise("File not found: #{path}")
        end

      [] ->
        Mix.raise("Usage: mix zixir.run <file.zixir>")
    end
  end
end
