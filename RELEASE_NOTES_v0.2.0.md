# Zixir v0.2.0 — New update release

This release adds Python Bridge integration, 25+ engine operations, a module system, an interactive REPL, and pattern matching.

## What's new

- **Python Bridge** — Full integration with numpy/pandas support, circuit breaker, connection pooling, and retry logic.
- **25+ Engine Operations** — All aggregations, vector ops, transformations, search, matrix, and string operations.
- **Module System** — Import resolution, caching, and circular dependency detection.
- **Interactive REPL** — Multi-line input, variable persistence, built-in commands.
- **Pattern Matching** — Literal, variable, array patterns with guards.

## Requirements

- Elixir 1.14+ / OTP 25+
- Zig 0.10+ (Zigler 0.15; run `mix zig.get` after `mix deps.get`)
- Python 3.10+ (for specialist; optional if not using Python calls)

## Quick start

```bash
git clone https://github.com/Zixir-lang/Zixir.git
cd Zixir
git checkout v0.2.0
mix deps.get
mix zig.get
mix compile
mix test
mix zixir.run examples/hello.zixir
```

## License

Apache-2.0 — see [LICENSE](LICENSE).
