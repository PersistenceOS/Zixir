defmodule Zixir.Compiler.TypeHelper do
  @moduledoc "Utility functions for type manipulation and string conversion"
  
  @doc "Convert a type to its string representation"
  def type_to_string(:int), do: "Int"
  def type_to_string(:float), do: "Float"
  def type_to_string(:bool), do: "Bool"
  def type_to_string(:string), do: "String"
  def type_to_string(:void), do: "Void"
  def type_to_string({:array, t}), do: "[#{type_to_string(t)}]"
  def type_to_string({:function, args, ret}) do
    args_str = Enum.map(args, &type_to_string/1) |> Enum.join(", ")
    "(#{args_str}) -> #{type_to_string(ret)}"
  end
  def type_to_string({:var, id}), do: "'t#{id}"
  def type_to_string({:poly, name, params}) do
    params_str = Enum.map(params, &type_to_string/1) |> Enum.join(", ")
    "#{name}<#{params_str}>"
  end
  def type_to_string(t), do: inspect(t)
end
