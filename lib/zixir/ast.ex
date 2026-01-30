defmodule Zixir.AST do
  @moduledoc """
  AST node types for Zixir source. All nodes carry line/column for error reporting.
  
  Note: The Zixir compiler uses a tuple-based AST representation rather than structs
  for performance and simplicity. The tuple format is:
  
  - `{:program, statements}` - Root node containing list of statements
  - `{:let, name, value, line, column}` - Variable binding
  - `{:function, name, params, return_type, body, is_public, line, column}` - Function definition
  - `{:number, value, line, column}` - Numeric literal
  - `{:string, value, line, column}` - String literal
  - `{:bool, value, line, column}` - Boolean literal
  - `{:var, name, line, column}` - Variable reference
  - `{:binop, operator, left, right}` - Binary operation
  - `{:unary, operator, expr, line, column}` - Unary operation
  - `{:call, function, args}` - Function call
  - `{:if, condition, then_block, else_block, line, column}` - Conditional
  - `{:block, statements}` - Block of statements
  - `{:array, elements, line, column}` - Array literal
  - `{:index, array, index}` - Array indexing
  - `{:field, object, field}` - Field access
  - `{:pipe, left, right}` - Pipe operator
  - `{:match, value, clauses, line, column}` - Pattern matching
  - `{:lambda, params, return_type, body, line, column}` - Anonymous function
  - `{:type_def, name, definition, line, column}` - Type definition
  - `{:import, path, line, column}` - Import statement
  - `{:while, condition, body, line, column}` - While loop
  - `{:for, var, iterable, body, line, column}` - For loop
  - `{:return, value, line, column}` - Return statement
  """

  defmodule Location do
    @moduledoc "Source location with line and column information"
    @enforce_keys [:line, :column]
    defstruct [:line, :column]
    
    @type t :: %__MODULE__{line: non_neg_integer(), column: non_neg_integer()}
  end
end
