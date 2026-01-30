# Zixir Quick Reference

## Syntax Cheat Sheet

### Basic Structure
```zixir
# Comments start with #
let name = value     # Variable binding
expression           # Last expression is the result
```

### Data Types
```zixir
42                   # Integer
3.14                 # Float
"hello"              # String
true / false         # Boolean
[1, 2, 3]            # Array
```

### Operations
```zixir
# Arithmetic
x + y                # Addition
x - y                # Subtraction
x * y                # Multiplication
x / y                # Division

# Engine (Zig) - Fast!
engine.list_sum([1.0, 2.0, 3.0])
engine.list_product([1.0, 2.0, 3.0])
engine.dot_product([1.0, 2.0], [3.0, 4.0])
engine.string_count("hello")

# Python Integration
python "math" "sqrt" (16.0)
python "numpy" "mean" ([1.0, 2.0, 3.0])
```

## CLI Commands

```bash
# Run a file
mix zixir run file.zr

# Compile to binary
mix zixir compile file.zr

# Type check
mix zixir check file.zr

# Interactive REPL
mix zixir repl

# With options
mix zixir run file.zr --verbose --optimize release_fast
```

## Elixir API

```elixir
# Evaluate Zixir code
Zixir.eval("engine.list_sum([1.0, 2.0])")
# => {:ok, 3.0}

# Run and return result (raises on error)
Zixir.run("let x = 5\nx * 2")
# => 10

# Direct engine call (fastest)
Zixir.run_engine(:list_sum, [[1.0, 2.0, 3.0]])
# => 6.0

# Direct Python call
Zixir.call_python("math", "sqrt", [16.0])
# => 4.0
```

## Common Patterns

### Pattern 1: Calculate Statistics
```zixir
let data = [1.0, 2.0, 3.0, 4.0, 5.0]
let sum = engine.list_sum(data)
let product = engine.list_product(data)
let mean = python "numpy" "mean" (data)
[sum, product, mean]
```

### Pattern 2: String Processing
```zixir
let text = "Hello, World!"
let length = engine.string_count(text)
length
```

### Pattern 3: Vector Math
```zixir
let a = [1.0, 2.0, 3.0]
let b = [4.0, 5.0, 6.0]
engine.dot_product(a, b)
```

### Pattern 4: Combine Operations
```zixir
let x = engine.list_sum([1.0, 2.0])
let y = engine.string_count("hi")
x + y
```

## File Extension
- Use `.zr` for Zixir source files

## Performance Tips
1. ✅ Use `engine.*` for array math (fast Zig NIFs)
2. ✅ Use arrays of floats `[1.0, 2.0]` not integers `[1, 2]` for engine ops
3. ⚠️ Python calls have overhead - batch when possible
4. ✅ Last expression is automatically returned

## Error Messages
- Syntax errors show line:column
- Type errors show expected vs actual type
- Python errors show module.function that failed

## Getting Help
- Full guide: `GUIDE.md`
- Language spec: `docs/LANGUAGE.md`
- Examples: `examples/` directory
- Tests: `mix test`