defmodule Zixir.Python.Protocol do
  @moduledoc """
  Single place for wire format between Elixir and Python.
  One JSON line per request and response. Map Elixir terms to Python types and back here only.
  """

  @doc """
  Encode request: module, function, args -> JSON line (binary).
  """
  def encode_request(module, function, args) do
    map = %{
      "m" => to_string(module),
      "f" => to_string(function),
      "a" => elixir_to_wire(args)
    }
    Jason.encode!(map) <> "\n"
  end

  @doc """
  Decode response line (binary) -> {:ok, term} or {:error, reason}.
  """
  def decode_response(line) when is_binary(line) do
    line = String.trim(line)
    if line == "" do
      {:error, :empty_line}
    else
      case Jason.decode(line) do
        {:ok, %{"ok" => value}} -> {:ok, wire_to_elixir(value)}
        {:ok, %{"error" => reason}} -> {:error, to_string(reason)}
        {:ok, _} -> {:error, :invalid_response}
        {:error, _} -> {:error, :decode_failed}
      end
    end
  end

  defp elixir_to_wire(list) when is_list(list), do: Enum.map(list, &elixir_to_wire/1)
  defp elixir_to_wire(map) when is_map(map), do: Map.new(map, fn {k, v} -> {to_string(k), elixir_to_wire(v)} end)
  defp elixir_to_wire(bin) when is_binary(bin), do: bin
  defp elixir_to_wire(atom) when is_atom(atom), do: to_string(atom)
  defp elixir_to_wire(num) when is_number(num), do: num
  defp elixir_to_wire(nil), do: nil
  defp elixir_to_wire(other), do: other

  defp wire_to_elixir(list) when is_list(list), do: Enum.map(list, &wire_to_elixir/1)
  defp wire_to_elixir(map) when is_map(map), do: Map.new(map, fn {k, v} -> {k, wire_to_elixir(v)} end)
  defp wire_to_elixir(other), do: other
end
