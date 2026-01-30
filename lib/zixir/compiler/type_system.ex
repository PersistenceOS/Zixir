defmodule Zixir.Compiler.TypeSystem do
  @moduledoc """
  Phase 3: Type inference and checking system for Zixir.
  
  Implements Hindley-Milner style type inference with support for:
  - Parametric polymorphism
  - Gradual typing (explicit types override inferred)
  - Type checking at compile time
  """

  defmodule Type do
    @moduledoc "Type representations"
    
    # Base types
    defstruct [:kind, :name, :params]
    
    @type t :: 
      :int |
      :float |
      :bool |
      :string |
      :void |
      {:array, t} |
      {:function, [t], t} |
      {:var, integer()} |  # Type variable for inference
      {:poly, String.t(), [t]}  # Parametric type
    
    def int(), do: :int
    def float(), do: :float
    def bool(), do: :bool
    def string(), do: :string
    def void(), do: :void
    def array(elem_type), do: {:array, elem_type}
    def function(args, ret), do: {:function, args, ret}
    def var(id), do: {:var, id}
    def poly(name, params), do: {:poly, name, params}
  end

  # Public type_to_string function for use throughout the module
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

  defmodule TypeError do
    defexception [:message, :location, :expected, :actual]
    
    # Local type_to_string implementation - must be defined before use
    defp type_to_string(:int), do: "Int"
    defp type_to_string(:float), do: "Float"
    defp type_to_string(:bool), do: "Bool"
    defp type_to_string(:string), do: "String"
    defp type_to_string(:void), do: "Void"
    defp type_to_string({:array, t}), do: "[#{type_to_string(t)}]"
    defp type_to_string({:function, args, ret}) do
      args_str = Enum.map(args, &type_to_string/1) |> Enum.join(", ")
      "(#{args_str}) -> #{type_to_string(ret)}"
    end
    defp type_to_string({:var, id}), do: "'t#{id}"
    defp type_to_string({:poly, name, params}) do
      params_str = Enum.map(params, &type_to_string/1) |> Enum.join(", ")
      "#{name}<#{params_str}>"
    end
    defp type_to_string(t), do: inspect(t)
    
    @impl true
    def exception(opts) do
      message = opts[:message] || format_error(opts)
      %TypeError{
        message: message,
        location: opts[:location],
        expected: opts[:expected],
        actual: opts[:actual]
      }
    end
    
    defp format_error(opts) do
      expected = type_to_string(opts[:expected])
      actual = type_to_string(opts[:actual])
      "Type mismatch: expected #{expected}, got #{actual}"
    end
  end

  @doc """
  Infer types for all expressions in the AST.
  Returns {:ok, typed_ast} or {:error, TypeError}
  """
  def infer(ast) do
    # Initialize type environment and variable counter
    env = %{}
    var_counter = 0
    
    try do
      {typed_ast, _final_env, _final_counter} = infer_program(ast, env, var_counter)
      {:ok, typed_ast}
    rescue
      e in TypeError -> {:error, e}
    end
  end

  @doc """
  Check if an expression matches an expected type.
  """
  def check_type(expr, expected_type, env) do
    {typed_expr, _new_env, _counter} = infer_expr(expr, env, 0)
    inferred_type = get_type(typed_expr)
    
    if types_match?(inferred_type, expected_type) do
      :ok
    else
      {:error, "Expected #{type_to_string(expected_type)}, got #{type_to_string(inferred_type)}"}
    end
  end

  # Type inference implementation
  
  defp infer_program({:program, statements}, env, counter) do
    {typed_stmts, new_env, new_counter} = 
      Enum.reduce(statements, {[], env, counter}, fn stmt, {acc, e, c} ->
        {typed_stmt, new_e, new_c} = infer_statement(stmt, e, c)
        {[typed_stmt | acc], new_e, new_c}
      end)
    
    {{:program, Enum.reverse(typed_stmts)}, new_env, new_counter}
  end

  defp infer_statement({:function, name, params, return_type, body, is_pub, line, col}, env, counter) do
    # Create type variables for parameters if types not specified
    {param_types, counter} = 
      Enum.map_reduce(params, counter, fn {_pname, ptype}, c ->
        case ptype do
          {:type, :auto} -> 
            {Type.var(c), c + 1}
          {:type, t} -> 
            {zixir_type_to_internal(t), c}
          t -> 
            {zixir_type_to_internal(t), c}
        end
      end)
    
    # Determine return type
    ret_type = case return_type do
      {:type, :auto} -> Type.var(counter)
      {:type, t} -> zixir_type_to_internal(t)
      t -> zixir_type_to_internal(t)
    end
    
    counter = if match?({:var, _}, ret_type), do: counter + 1, else: counter
    
    # Add function to environment
    func_type = Type.function(param_types, ret_type)
    env = Map.put(env, name, func_type)
    
    # Add parameters to environment for body inference
    body_env = 
      Enum.reduce(Enum.zip(params, param_types), env, fn {{pname, _}, ptype}, e ->
        Map.put(e, pname, ptype)
      end)
    
    # Infer body type
    {typed_body, _final_body_env, counter} = infer_statement(body, body_env, counter)
    
    # Unify body type with return type
    body_type = get_type(typed_body)
    {unified_ret, _} = unify(ret_type, body_type, %{})
    
    typed_func = {:function, name, Enum.zip(params, param_types), unified_ret, typed_body, is_pub, line, col}
    {set_type(typed_func, func_type), env, counter}
  end

  defp infer_statement({:let, name, expr, line, col}, env, counter) do
    {typed_expr, new_env, counter} = infer_expr(expr, env, counter)
    expr_type = get_type(typed_expr)
    
    new_env = Map.put(new_env, name, expr_type)
    typed_let = {:let, name, typed_expr, line, col}
    {set_type(typed_let, expr_type), new_env, counter}
  end

  defp infer_statement({:block, statements}, env, counter) do
    {typed_stmts, new_env, counter} = 
      Enum.reduce(statements, {[], env, counter}, fn stmt, {acc, e, c} ->
        {typed_stmt, new_e, new_c} = infer_statement(stmt, e, c)
        {[typed_stmt | acc], new_e, new_c}
      end)
    
    # Block type is the type of the last statement
    block_type = if length(typed_stmts) > 0 do
      get_type(hd(typed_stmts))
    else
      Type.void()
    end
    
    typed_block = {:block, Enum.reverse(typed_stmts)}
    {set_type(typed_block, block_type), new_env, counter}
  end

  defp infer_statement(stmt, env, counter) do
    # Treat as expression statement
    infer_expr(stmt, env, counter)
  end

  defp infer_expr({:number, n, line, col}, env, counter) when is_integer(n) do
    {set_type({:number, n, line, col}, Type.int()), env, counter}
  end

  defp infer_expr({:number, n, line, col}, env, counter) when is_float(n) do
    {set_type({:number, n, line, col}, Type.float()), env, counter}
  end

  defp infer_expr({:string, _, line, col}, env, counter) do
    {set_type({:string, :inferred, line, col}, Type.string()), env, counter}
  end

  defp infer_expr({:bool, _, line, col}, env, counter) do
    {set_type({:bool, :inferred, line, col}, Type.bool()), env, counter}
  end

  defp infer_expr({:var, name, line, col}, env, counter) do
    case Map.get(env, name) do
      nil -> 
        # Create new type variable for unknown variable
        type = Type.var(counter)
        new_env = Map.put(env, name, type)
        {set_type({:var, name, line, col}, type), new_env, counter + 1}
      
      type -> 
        {set_type({:var, name, line, col}, type), env, counter}
    end
  end

  defp infer_expr({:binop, op, left, right}, env, counter) do
    {typed_left, env, counter} = infer_expr(left, env, counter)
    {typed_right, env, counter} = infer_expr(right, env, counter)
    
    left_type = get_type(typed_left)
    right_type = get_type(typed_right)
    
    # Determine result type based on operator
    result_type = case op do
      :add -> infer_arithmetic_type(left_type, right_type)
      :sub -> infer_arithmetic_type(left_type, right_type)
      :mul -> infer_arithmetic_type(left_type, right_type)
      :div -> Type.float()  # Division always returns float
      :and -> Type.bool()
      :or -> Type.bool()
      :eq -> Type.bool()
      :neq -> Type.bool()
      :lt -> Type.bool()
      :gt -> Type.bool()
      _ -> Type.var(counter)
    end
    
    typed_binop = {:binop, op, typed_left, typed_right}
    {set_type(typed_binop, result_type), env, counter}
  end

  defp infer_expr({:unary, op, expr, line, col}, env, counter) do
    {typed_expr, env, counter} = infer_expr(expr, env, counter)
    expr_type = get_type(typed_expr)
    
    result_type = case op do
      :neg -> expr_type
      :not -> Type.bool()
      _ -> Type.var(counter)
    end
    
    typed_unary = {:unary, op, typed_expr, line, col}
    {set_type(typed_unary, result_type), env, counter}
  end

  defp infer_expr({:call, func, args}, env, counter) do
    {typed_func, env, counter} = infer_expr(func, env, counter)
    func_type = get_type(typed_func)
    
    {typed_args, {env, counter}} = 
      Enum.map_reduce(args, {env, counter}, fn arg, {e, c} ->
        {typed_arg, new_e, new_c} = infer_expr(arg, e, c)
        {typed_arg, {new_e, new_c}}
      end)
    
    arg_types = Enum.map(typed_args, &get_type/1)
    
    # Infer or unify return type
    ret_type = case func_type do
      {:function, expected_args, expected_ret} ->
        # Unify argument types
        Enum.zip(arg_types, expected_args)
        |> Enum.reduce({expected_ret, %{}}, fn {actual, expected}, {ret, subst} ->
          {_unified, new_subst} = unify(actual, expected, subst)
          {apply_substitution(ret, new_subst), Map.merge(subst, new_subst)}
        end)
        |> elem(0)
      
      {:var, _} -> 
        # Create function type with new return variable
        ret_var = Type.var(counter)
        new_func_type = Type.function(arg_types, ret_var)
        {_unified, _} = unify(func_type, new_func_type, %{})
        ret_var
      
      _ -> 
        Type.var(counter)
    end
    
    counter = if match?({:var, _}, ret_type), do: counter + 1, else: counter
    
    typed_call = {:call, typed_func, typed_args}
    {set_type(typed_call, ret_type), env, counter}
  end

  defp infer_expr({:if, cond_expr, then_block, else_block, line, col}, env, counter) do
    {typed_cond, env, counter} = infer_expr(cond_expr, env, counter)
    {typed_then, env, counter} = infer_statement(then_block, env, counter)
    
    then_type = get_type(typed_then)
    
    if else_block do
      {typed_else, env, counter} = infer_statement(else_block, env, counter)
      else_type = get_type(typed_else)
      
      # Unify then and else types
      {unified_type, _} = unify(then_type, else_type, %{})
      
      typed_if = {:if, typed_cond, typed_then, typed_else, line, col}
      {set_type(typed_if, unified_type), env, counter}
    else
      typed_if = {:if, typed_cond, typed_then, nil, line, col}
      {set_type(typed_if, then_type), env, counter}
    end
  end

  defp infer_expr({:array, elements, line, col}, env, counter) do
    {typed_elements, {env, counter}} = 
      Enum.map_reduce(elements, {env, counter}, fn elem, {e, c} ->
        {typed_elem, new_e, new_c} = infer_expr(elem, e, c)
        {typed_elem, {new_e, new_c}}
      end)
    
    elem_types = Enum.map(typed_elements, &get_type/1)
    
    # Unify all element types
    array_elem_type = 
      if length(elem_types) > 0 do
        Enum.reduce(tl(elem_types), hd(elem_types), fn t, acc ->
          {unified, _} = unify(acc, t, %{})
          unified
        end)
      else
        Type.var(counter)
      end
    
    counter = if match?({:var, _}, array_elem_type), do: counter + 1, else: counter
    
    typed_array = {:array, typed_elements, line, col}
    {set_type(typed_array, Type.array(array_elem_type)), env, counter}
  end

  defp infer_expr({:index, array, index}, env, counter) do
    {typed_array, env, counter} = infer_expr(array, env, counter)
    {typed_index, env, counter} = infer_expr(index, env, counter)
    
    array_type = get_type(typed_array)
    
    elem_type = case array_type do
      {:array, t} -> t
      {:var, _} -> Type.var(counter)
      _ -> Type.var(counter)
    end
    
    counter = if match?({:var, _}, elem_type), do: counter + 1, else: counter
    
    typed_index_expr = {:index, typed_array, typed_index}
    {set_type(typed_index_expr, elem_type), env, counter}
  end

  defp infer_expr(expr, env, counter) do
    # Unknown expression type - create type variable
    {set_type(expr, Type.var(counter)), env, counter + 1}
  end

  # Type unification
  defp unify(t1, t2, subst) when t1 == t2, do: {t1, subst}
  
  defp unify({:var, id}, t, subst) do
    case Map.get(subst, id) do
      nil -> 
        if occurs_in?(id, t) do
          raise TypeError, message: "Occurs check failed - infinite type", location: 0
        end
        {t, Map.put(subst, id, t)}
      
      bound -> unify(bound, t, subst)
    end
  end
  
  defp unify(t, {:var, id}, subst), do: unify({:var, id}, t, subst)
  
  defp unify({:array, t1}, {:array, t2}, subst) do
    {unified, new_subst} = unify(t1, t2, subst)
    {{:array, unified}, new_subst}
  end
  
  defp unify({:function, args1, ret1}, {:function, args2, ret2}, subst) do
    if length(args1) != length(args2) do
      raise TypeError, message: "Function arity mismatch", location: 0
    end
    
    {unified_args, subst} = 
      Enum.zip(args1, args2)
      |> Enum.reduce({[], subst}, fn {a1, a2}, {acc, s} ->
        {u, new_s} = unify(a1, a2, s)
        {[u | acc], new_s}
      end)
    
    {unified_ret, final_subst} = unify(ret1, ret2, subst)
    {{:function, Enum.reverse(unified_args), unified_ret}, final_subst}
  end
  
  defp unify(t1, t2, _subst) do
    raise TypeError, 
      message: "Cannot unify #{type_to_string(t1)} with #{type_to_string(t2)}", 
      location: 0
  end

  defp occurs_in?(id, {:var, id2}), do: id == id2
  defp occurs_in?(id, {:array, t}), do: occurs_in?(id, t)
  defp occurs_in?(id, {:function, args, ret}) do
    Enum.any?(args, &occurs_in?(id, &1)) or occurs_in?(id, ret)
  end
  defp occurs_in?(_, _), do: false

  defp apply_substitution({:var, id}, subst) do
    case Map.get(subst, id) do
      nil -> {:var, id}
      t -> apply_substitution(t, subst)
    end
  end
  
  defp apply_substitution({:array, t}, subst) do
    {:array, apply_substitution(t, subst)}
  end
  
  defp apply_substitution({:function, args, ret}, subst) do
    {:function, 
     Enum.map(args, &apply_substitution(&1, subst)),
     apply_substitution(ret, subst)}
  end
  
  defp apply_substitution(t, _), do: t

  # Helper functions
  defp infer_arithmetic_type(:int, :int), do: :int
  defp infer_arithmetic_type(:float, _), do: :float
  defp infer_arithmetic_type(_, :float), do: :float
  defp infer_arithmetic_type({:var, _} = v, _), do: v
  defp infer_arithmetic_type(_, {:var, _} = v), do: v
  defp infer_arithmetic_type(_, _), do: :float

  defp zixir_type_to_internal(:Int), do: :int
  defp zixir_type_to_internal(:Float), do: :float
  defp zixir_type_to_internal(:Bool), do: :bool
  defp zixir_type_to_internal(:String), do: :string
  defp zixir_type_to_internal(:Void), do: :void
  defp zixir_type_to_internal(t) when is_atom(t), do: t
  defp zixir_type_to_internal(_), do: {:var, 0}

  defp types_match?(t1, t2), do: t1 == t2

  defp get_type({_, _, type}), do: type
  defp get_type({:type, type}), do: type
  defp get_type(_), do: :unknown

  defp set_type({tag, a, b, c, d}, type), do: {tag, a, b, c, d, type}
  defp set_type({tag, a, b, c}, type), do: {tag, a, b, c, type}
  defp set_type({tag, a, b}, type), do: {tag, a, b, type}
  defp set_type({tag, a}, type), do: {tag, a, type}
  defp set_type(term, type), do: {:type, type, term}

  @doc """
  Get the type of an expression from the typed AST.
  """
  def expr_type({_, _, _, _, _, type}), do: type
  def expr_type({_, _, _, _, type}), do: type
  def expr_type({_, _, _, type}), do: type
  def expr_type({_, _, type}), do: type
  def expr_type({_, type}), do: type
  def expr_type({:type, type, _}), do: type
  def expr_type(_), do: :unknown

  @doc """
  Check if a type is concrete (fully resolved, no type variables).
  """
  def concrete_type?({:var, _}), do: false
  def concrete_type?({:array, elem_type}), do: concrete_type?(elem_type)
  def concrete_type?({:function, args, ret}) do
    Enum.all?(args, &concrete_type?/1) and concrete_type?(ret)
  end
  def concrete_type?({:poly, _, params}) do
    Enum.all?(params, &concrete_type?/1)
  end
  def concrete_type?(_), do: true

  @doc """
  Format a type for display to the user.
  """
  def format_type(type), do: type_to_string(type)

  @doc """
  Run type inference and return detailed results.
  """
  def infer_detailed(ast) do
    case infer(ast) do
      {:ok, typed_ast} ->
        stats = collect_type_stats(typed_ast)
        {:ok, typed_ast, stats}
      
      {:error, error} ->
        {:error, error}
    end
  end

  defp collect_type_stats({:program, statements}) do
    types = collect_all_types(statements, [])
    
    %{
      total_expressions: length(types),
      concrete_types: Enum.count(types, &concrete_type?/1),
      type_variables: Enum.count(types, fn {:var, _} -> true; _ -> false end),
      function_types: Enum.count(types, fn {:function, _, _} -> true; _ -> false end),
      array_types: Enum.count(types, fn {:array, _} -> true; _ -> false end)
    }
  end

  defp collect_all_types(statements, acc) when is_list(statements) do
    Enum.reduce(statements, acc, fn stmt, a ->
      collect_all_types(stmt, a)
    end)
  end

  defp collect_all_types({:function, _, _, _, body, _, _, _, _}, acc) do
    collect_all_types(body, acc)
  end

  defp collect_all_types({:let, _, expr, _, _, _}, acc) do
    collect_all_types(expr, acc)
  end

  defp collect_all_types({:block, statements}, acc) do
    collect_all_types(statements, acc)
  end

  defp collect_all_types({_, _, _, _, _, type}, acc) do
    [type | acc]
  end

  defp collect_all_types({_, _, _, _, type}, acc) do
    [type | acc]
  end

  defp collect_all_types({_, _, _, type}, acc) do
    [type | acc]
  end

  defp collect_all_types({_, _, type}, acc) do
    [type | acc]
  end

  defp collect_all_types({_, type}, acc) do
    [type | acc]
  end

  defp collect_all_types({:type, type, _}, acc) do
    [type | acc]
  end

  defp collect_all_types(_, acc), do: acc
end
