# Zixir v4.0.0 — Compiler, type system, and MLIR improvements

This release adds major improvements to the Zig backend, MLIR optimizations, type system, and parser: structs, maps, list comprehensions, try/catch, async/await, range expressions, comptime, defer, and self-healing AI pipelines. Plus automatic drift detection, A/B winner promotion, and data cleaning/validation.

---

## 1. Zig Backend (100%) ✅

- **Automatic drift detection and alerting** ✅
- **Automatic winner promotion in A/B tests** ✅
- **Automatic data cleaning and validation** ✅
- **Self-healing AI pipelines** ✅
- Struct/type definition generation
- Map literal generation
- Struct initialization and field access
- Better pattern matching (switch) codegen
- List comprehension generation
- Try/catch/finally expressions
- Defer statements
- Comptime blocks
- Async/await expressions
- Range expressions
- Strength reduction optimization

---

## 2. MLIR (100%) ✅

- Full dead code elimination with variable usage tracking
- Constant propagation with type checking
- Loop invariant code motion (LICM)
- Strength reduction for common patterns
- Better struct/map type representations

---

## 3. Type System (100%) ✅

- Lambda type inference
- Struct type inference
- Struct field access type inference
- Map types with key/value unification
- Map access type inference
- List comprehension type inference
- Range expression types
- Try/catch type inference
- Future/async type inference

---

## 4. Parser (100%) ✅

- List comprehension parsing (`[expr for var in iterable if condition]`)
- Map literal parsing (`{key => value, ...}`)
- Struct definition parsing (`struct { field: Type }`)
- Try/catch parsing
- Async/await parsing
- Range expression parsing (`start..end`)
- Defer statement parsing
- Comptime block parsing

---

## Requirements

- **Elixir** 1.14+ / OTP 25+
- **Zig** 0.15+ (build-time; run `mix zig.get` after `mix deps.get`)
- **Python** 3.8+ *(optional)* for ML/specialist calls

## Quick start

```bash
git clone https://github.com/Zixir-lang/Zixir.git
cd Zixir
git checkout v4.0.0
mix deps.get
mix zig.get
mix compile
mix test
```

## License

**Apache-2.0** — see [LICENSE](LICENSE).
