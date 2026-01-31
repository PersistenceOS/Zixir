# Zixir Programming Language - User Guide

## What is Zixir?

Zixir is a small, expression-oriented language and a three-tier runtime that combines:
- **Elixir** (orchestrator) - For concurrency, fault tolerance, and intent
- **Zig** (engine) - For memory-critical math and high-speed data operations
- **Python** (specialist) - For accessing Python libraries and ecosystem

## What is Zixir good at?

- **Array-heavy and numeric work** — Sums, products, dot products, and similar ops run in the Zig engine (NIFs), often 100–1000× faster than doing the same in pure Elixir. Use `engine.list_sum`, `engine.list_product`, `engine.dot_product` for hot paths.
- **One language, three backends** — You write Zixir; the runtime picks Elixir for orchestration, Zig for fast math, and Python when you need a library. No need to hand-write C/Zig bindings for every Python or numeric kernel.
- **Pipelines that mix math and ecosystem** — Express formulas and data steps in Zixir, call out to Python (e.g. numpy, plotting, APIs) where needed, and let the engine handle the heavy numeric parts.
- **Scripts and small tools** — A single Zixir program can do arithmetic, aggregate over arrays, and call Python for I/O or visualization, with predictable performance where it matters.

## Good use cases for Zixir

| Use case | Why Zixir fits |
|----------|----------------|
| **Data processing / analytics** | Engine ops for aggregates and dot products; Python for pandas/numpy or plotting when needed. |
| **Simulation / game math** | Positions, velocities, and dot products in the engine; game loop in Elixir; display or UI in Python (e.g. tkinter, pygame). |
| **Scientific or numerical scripting** | Write formulas in Zixir, use the engine for hot loops, call Python for scipy/numpy or file formats. |
| **Tooling and automation** | Elixir orchestrates steps; Zixir handles numeric logic; Python handles formats, APIs, or GUIs. |
| **Learning or teaching** | One syntax that spans “math” (Zixir), “fast kernel” (Zig), and “ecosystem” (Python) in a single runtime. |

As the language grows (e.g. functions, control flow, more engine ops), it will fit larger programs and more domains while keeping the same three-tier split.

### Zixir for game development

Zixir fits specific **areas** of game development rather than replacing a full engine:

| Area | How Zixir helps |
|------|------------------|
| **Game math / physics** | Positions, velocities, dot products, and aggregates run in the **Zig engine** (NIFs). Use `engine.list_sum`, `engine.dot_product` for movement, scoring, or collision-style math. The language expresses the formulas; the engine runs them fast. |
| **Prototyping & small games** | Elixir runs the loop; Zixir (or `.zr` scripts) computes state each frame; Python (tkinter, pygame) handles display and input. Good for 2D prototypes, tools, and learning. |
| **Simulation & numeric logic** | Damage formulas, stats, economy, or any numeric game logic can live in Zixir and hit the engine for hot paths. Elixir coordinates; Python is only for I/O or rendering. |
| **Game tooling & pipelines** | Level data, balance tables, or asset pipelines: Elixir orchestrates; Zixir does numeric/aggregate logic; Python handles file formats or scripting. |
| **Server-side game logic** | For matchmaking, scoring, or stats, Elixir's concurrency plus Zixir + engine for numeric work can handle server-side game logic without Python in the hot path. |

Zixir is **not** aimed at building a full AAA engine (no 3D renderer, no custom low-level loop in Zixir yet). It **is** a good fit for: game math, 2D prototypes, simulation, tooling, and server-side numeric logic—all with one language and a clear split between fast kernels (Zig) and ecosystem (Python).

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

## 2D game with GUI

A minimal 2D game that uses the **language** for position math (via the **Zig engine**), Elixir for bounce, and Python only for drawing:

```bash
mix zixir game
```

Or: `mix run examples/gui_game.exs`

- **Zixir (language):** Each frame we run Zixir source like `engine.list_sum([pos, vel * dt])` — your language, not Python expressions.
- **Zig (engine):** That call runs in the Zig NIF (`engine.list_sum`), so the hot path is native code, not Python.
- **Elixir (orchestrator):** Handles bounce (flip velocity at walls). Python never sees the math.
- **Python/tkinter:** Only draws the ball at the positions we send; it does not evaluate Zixir or run the engine.

The game window shows the Zixir snippet and “Zixir + Zig + Elixir → Python” so it’s clear the language and engine are in the loop. Close the window when done.

### Why it can look like “just Python”

Because the **window** is Python/tkinter, it’s easy to think the whole program is Python. In our setup:

- **Python’s role:** Display only (window, canvas, timer). It does not run your language or the Zig engine.
- **Our language’s role:** The position each frame is computed by **Zixir** (`let pos = ... let vel = ... engine.list_sum([pos, vel * dt])`) and the **Zig engine** (the NIF that does the sum). So the language and engine **look** different (you see the Zixir snippet in the GUI) and **perform** differently (native Zig in the hot path, not Python).
- **Elixir’s role:** Drives the loop, does bounce logic, and calls Zixir.eval and the Python port. So the “program” is Zixir + Elixir; Python is just the display backend.

To make that visible, the game window displays the Zixir expression and the pipeline (Zixir + Zig + Elixir → Python). For more “language in the foreground” examples, run `.zr` files with `mix zixir run` or `mix zixir repl` and use `engine.*` in your source so the Zig layer is clearly involved.

### Using Zixir with SDL2

Yes. Zixir can be used with SDL2 (or similar native graphics APIs) instead of Python for display.

Right now the GUI examples use **Python/tkinter** as the display backend. To use **SDL2** you'd add it to the project and expose it to the runtime. Typical options:

| Approach | How it works |
|----------|----------------|
| **Zig NIFs** | Add SDL2 (or a Zig SDL2 wrapper) to the Zig side and expose SDL2 functions as new engine ops or a separate NIF module. Elixir/Zixir then calls e.g. `sdl2.init()`, `sdl2.create_window()`, `sdl2.render_clear()`, etc. Same pattern as the existing engine (Zigler NIFs). |
| **Port** | Run a separate process (C, Zig, or Rust) that links SDL2 and talks to Elixir over stdin/stdout or a socket. Elixir sends draw commands and receives input events. Similar to the Python port but with a native binary. |
| **Elixir SDL2 binding** | Use an existing Elixir SDL2 library (if available) and call it from the game loop; Zixir still does the math via `Zixir.eval` and engine ops. |

In all cases, **Zixir and the Zig engine** keep doing game math; **SDL2** replaces Python as the display and input backend. So: Zixir + Zig (language + engine) + Elixir (loop) + SDL2 (window/rendering/input) instead of + Python/tkinter.

## Resources

- **Language Spec**: See `docs/LANGUAGE.md`
- **Examples**: Check `examples/` directory
- **Tests**: Run `mix test` to see working examples
- **Architecture**: See `project_Analysis_for_fork.md`

## Next Steps

1. Try the examples in `examples/` directory
2. Run `mix zixir game` to see the 2D ball game
3. Run `mix zixir repl` to experiment interactively
4. Read the full language specification in `docs/LANGUAGE.md`
5. Check out the test files in `test/` for more usage patterns

Happy coding with Zixir! 🚀