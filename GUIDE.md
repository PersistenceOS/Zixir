# Zixir Programming Language - User Guide

## What is Zixir?

Zixir is a three-tier programming language that combines:
- **Elixir** (orchestrator) - For concurrency, fault tolerance, and intent
- **Zig** (engine) - For memory-critical math and high-speed data operations
- **Python** (specialist) - For accessing Python libraries and ecosystem

## Quick Start

### Installation

```bash
# 1. Install dependencies
mix deps.get

# 2. Install Zig (via Zigler)
mix zig.get

# 3. Compile the project
mix compile

# 4. Run tests
mix test
```

### Your First Zixir Program

Create a file `hello.zr`:

```zixir
# Basic arithmetic
let x = 10
let y = 5
x + y
# Result: 15
```

Run it:

```bash
mix zixir run hello.zr
```

Or use the Elixir API:

```elixir
Zixir.run("let x = 10\nlet y = 5\nx + y")
# => 15
```

## Language Syntax

### 1. Comments

```zixir
# This is a comment
# Comments start with # and go to end of line
```

### 2. Variables (let bindings)

```zixir
let x = 42           # Integer
let pi = 3.14159     # Float
let name = "Zixir"   # String
let items = [1, 2, 3] # Array
```

### 3. Literals

**Numbers:**
```zixir
42       # Integer
3.14     # Float
```

**Strings:**
```zixir
"hello world"
"line 1\nline 2"  # With escape sequences
```

**Arrays:**
```zixir
[1, 2, 3]
[1.0, 2.0, 3.0]  # Arrays of floats for engine operations
```

**Booleans:**
```zixir
true
false
```

### 4. Binary Operations

```zixir
1 + 2    # Addition
10 - 5   # Subtraction
4 * 3    # Multiplication
8 / 2    # Division
```

### 5. Engine Operations (Zig NIFs)

High-performance operations implemented in Zig:

```zixir
# Sum of array elements
engine.list_sum([1.0, 2.0, 3.0])
# => 6.0

# Product of array elements
engine.list_product([2.0, 3.0, 4.0])
# => 24.0

# Dot product of two arrays
engine.dot_product([1.0, 2.0, 3.0], [4.0, 5.0, 6.0])
# => 32.0

# String length (byte count)
engine.string_count("hello")
# => 5
```

### 6. Python Integration

Call Python libraries directly:

```zixir
# Call Python math.sqrt
python "math" "sqrt" (16.0)
# => 4.0

# Call numpy functions
python "numpy" "mean" ([1.0, 2.0, 3.0, 4.0, 5.0])
# => 3.0
```

## Running Zixir Programs

### Method 1: CLI (mix zixir)

```bash
# Compile a .zr file to binary
mix zixir compile program.zr

# Compile and run immediately
mix zixir run program.zr

# Run with verbose output
mix zixir run program.zr --verbose

# Type check only
mix zixir check program.zr

# Start interactive REPL
mix zixir repl
```

### Method 2: Elixir API

```elixir
# Evaluate and get result tuple
Zixir.eval("engine.list_sum([1.0, 2.0, 3.0])")
# => {:ok, 6.0}

# Evaluate and raise on error
Zixir.run("let x = 5\nx * 2")
# => 10

# Direct engine calls (fastest)
Zixir.run_engine(:list_sum, [[1.0, 2.0, 3.0]])
# => 6.0

# Direct Python calls
Zixir.call_python("math", "sqrt", [16.0])
# => 4.0
```

## Complete Examples

### Example 1: Basic Math

```zixir
# math_example.zr
let a = 10
let b = 20
let sum = a + b
let product = a * b

engine.list_sum([sum, product])
# Result: 230.0 (30 + 200)
```

### Example 2: Data Processing

```zixir
# data_processing.zr
let data = [1.0, 2.0, 3.0, 4.0, 5.0]
let sum = engine.list_sum(data)
let product = engine.list_product(data)
let count = engine.string_count("dataset")

# Return multiple results as array
[sum, product, count]
# Result: [15.0, 120.0, 7]
```

### Example 3: Python Integration

```zixir
# python_integration.zr
let numbers = [1.0, 2.0, 3.0, 4.0, 5.0]

# Use Python for advanced math
let mean = python "numpy" "mean" (numbers)
let std = python "numpy" "std" (numbers)
let sqrt_sum = python "math" "sqrt" (engine.list_sum(numbers))

[mean, std, sqrt_sum]
# Result: [3.0, ~1.414, ~3.873]
```

### Example 4: String Processing

```zixir
# string_example.zr
let greeting = "Hello, Zixir!"
let length = engine.string_count(greeting)
let exclamation = "!"

length + engine.string_count(exclamation)
# Result: 16 (15 + 1)
```

## Advanced Features

### Type System (Planned)

Zixir has a type system that infers types automatically:

```zixir
# Types are inferred
let x = 42        # Int
let y = 3.14      # Float
let s = "hello"   # String
let arr = [1, 2]  # [Int]
```

### Functions (Planned)

```zixir
fn add(x: Int, y: Int) -> Int:
  x + y

fn calculate(data: [Float]) -> Float:
  engine.list_sum(data) / data.length
```

### If Expressions (Planned)

```zixir
let x = 10
let result = if x > 5: "big" else: "small"
```

## CLI Reference

### mix zixir commands

| Command | Description | Example |
|---------|-------------|---------|
| `compile` | Compile to native binary | `mix zixir compile file.zr` |
| `run` | Compile and execute | `mix zixir run file.zr` |
| `check` | Type check only | `mix zixir check file.zr` |
| `repl` | Interactive shell | `mix zixir repl` |
| `test` | Run tests | `mix zixir test` |
| `python` | Test Python FFI | `mix zixir python` |

### Options

| Option | Description | Example |
|--------|-------------|---------|
| `--verbose` | Show detailed output | `mix zixir run file.zr --verbose` |
| `--optimize` | Set optimization level | `mix zixir compile file.zr --optimize release_fast` |
| `--output` | Set output path | `mix zixir compile file.zr --output myapp` |

## Performance Tips

1. **Use engine operations** for math on arrays - they're 100-1000x faster than pure Elixir
2. **Batch Python calls** - minimize Python interop overhead
3. **Use arrays of floats** - engine operations expect `[Float]` for best performance
4. **Avoid unnecessary variables** - the last expression is automatically returned

## Error Handling

```zixir
# Syntax errors show line and column
let x =    # Error: unexpected end of input

# Type errors (when type checking enabled)
let x = "hello"
x + 5      # Error: cannot add String and Int
```

## Troubleshooting

### "mix is not recognized"
Install Elixir and add to PATH: https://elixir-lang.org/install.html

### Python not found
Set Python path in config:
```elixir
config :zixir, :python_path, "/path/to/python"
```

### Compilation errors
Ensure you ran:
```bash
mix deps.get
mix zig.get
mix compile
```

## Resources

- **Language Spec**: See `docs/LANGUAGE.md`
- **Examples**: Check `examples/` directory
- **Tests**: Run `mix test` to see working examples
- **Architecture**: See `project_Analysis_for_fork.md`

## Next Steps

1. Try the examples in `examples/` directory
2. Run `mix zixir repl` to experiment interactively
3. Read the full language specification in `docs/LANGUAGE.md`
4. Check out the test files in `test/` for more usage patterns

Happy coding with Zixir! 🚀