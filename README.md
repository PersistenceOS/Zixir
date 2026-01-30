# Zixir

Three-tier runtime: **Elixir** (orchestrator), **Zig** (engine), **Python** (specialist). Compatible with Python libraries via ports; Zig for memory-critical math and high-speed data; Elixir for concurrency, fault tolerance, and intent.

## Requirements

- **Elixir** 1.14+ / OTP 25+
- **Zig** 0.10+ (Zigler fetches via `mix zig.get` after `mix deps.get`)
- **Python** 3.10+ (for specialist; recommend virtualenv)

## Supported platforms

- Windows, macOS, Linux. Test on your target OS (e.g. VS Code Ctrl+Shift+P) before rollout.
- **Elixir/OTP**: 1.14+ / 25+
- **Zig**: Zigler 0.15 expects Zig 0.15.x. Run `mix zig.get` so Zigler uses its cached 0.15.2; if you have Zig 0.16 on PATH, the verify script prefers the Zigler cache.
- **Python**: 3.10+ for specialist; recommend virtualenv or container for reproducible library calls.
- **Optional MLIR (Beaver)**: add `{:beaver, "~> 0.4"}` to deps on Unix only; Kinda (Beaver’s dep) does not support Windows.

## Environment

- Set `config :zixir, :python_path, "/path/to/python"` if Python is not on `PATH`.
- Python specialist script: `priv/python/port_bridge.py` (shipped with app; use `Application.app_dir(:zixir)` for path).
- Zig: Zigler compiles NIFs at compile time; ensure Zig is available when running `mix compile`.

## Entry point (agentic extension)

Single public API for invoking Zixir from an agentic coding extension:

- `Zixir.run_engine(op, args)` — hot path (math, data) → Zig.
- `Zixir.call_python(module, function, args)` — library calls → Python.

No duplicate routing or protocol code; intent and routing live in `Zixir.Intent`.

## Setup

```bash
mix deps.get
mix zig.get   # after deps.get, for Zigler
mix compile
```

For Python specialist: ensure Python is on `PATH` or set in config; recommend a virtualenv.

## Usage

### Zixir language (source)

Run Zixir source with `eval/1` or `run/1`:

```elixir
Zixir.eval("engine.list_sum([1.0, 2.0, 3.0])")
# => {:ok, 6.0}

Zixir.run("let x = 5\nlet y = 5\nx + y")
# => 10
```

Run a `.zixir` file:

```bash
mix zixir.run examples/hello.zixir
```

Grammar, types, and standard library: see [docs/LANGUAGE.md](docs/LANGUAGE.md).

### Elixir API

- `Zixir.run_engine/2` — hot path (math, data) → Zig NIFs
- `Zixir.call_python/3` — library calls → Python via port

See [project_Analysis_for_fork.md](project_Analysis_for_fork.md) for architecture and failure model.

## Build

```bash
mix compile
```

## Test

```bash
mix test
```

## Verification (full check)

From the project root, run in order:

```bash
mix deps.get
mix zig.get
mix compile
mix test
mix zixir.run examples/hello.zixir
```

Expected: tests pass; `examples/hello.zixir` prints `11.0`. On Windows run `scripts\verify.ps1`; if you see "mix is not recognized", install [Elixir](https://elixir-lang.org/install.html#windows) and add it to your PATH (or open a terminal from the Elixir start menu entry and run the script again).

## License

See LICENSE file if present.
