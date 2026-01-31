# Zixir v5.0.0 — Global CLI, Python FFI, Package Manager, GPU, Standard Library

This release adds a **global/portable CLI**, **Python FFI** (working), **Package Manager** (working), **GPU (CUDA)** enhancements, and an **expanded Standard Library** (100+ functions). Run Zixir from anywhere; install and manage packages; call Python natively; accelerate with CUDA; use a rich built-in library.

---

## 1. Global / Portable CLI ✅

- **Global CLI** — Install Zixir once, run `zixir` from any directory
- **Portable** — Single binary or script; no project-local install required
- **Cross-platform** — Windows, macOS, Linux support

---

## 2. Python FFI ✅ Working

- **Python FFI** — Native Python interop (not just port bridge)
- **Direct calls** — Lower latency, better type handling
- **Working** — Stable for production use

---

## 3. Package Manager ✅ Working

- **Package Manager** — Install, publish, and resolve Zixir packages
- **Dependency resolution** — Version constraints, lockfile
- **Working** — Ready for ecosystem use

---

## 4. GPU (CUDA) ✅ Enhanced

- **GPU (CUDA)** — Enhanced support for CUDA kernels
- **Auto-offload** — Detect and run suitable code on GPU
- **Performance** — Better integration and tuning

---

## 5. Standard Library ✅ Expanded (100+ functions)

- **Standard Library** — 100+ built-in functions
- **Engine** — Math, vectors, matrices, strings, lists, maps
- **Quality / Drift / Experiment** — Data validation, drift detection, A/B testing helpers
- **Workflow / Stream / Cache** — Orchestration, streaming, persistence

---

## Implementation status (v5.0)

| Feature            | Status      |
| ------------------ | ----------- |
| Global/Portable CLI | ✅ Supported |
| Python FFI         | ✅ Working   |
| Package Manager    | ✅ Working   |
| GPU (CUDA)         | ✅ Enhanced  |
| Standard Library   | ✅ Expanded (100+ functions) |

---

## Requirements

- **Elixir** 1.14+ / OTP 25+
- **Zig** 0.15+ (build-time; run `mix zig.get` after `mix deps.get`)
- **Python** 3.8+ *(optional)* for ML/specialist calls
- **CUDA** *(optional)* for GPU acceleration

## Quick start

```bash
git clone https://github.com/Zixir-lang/Zixir.git
cd Zixir
git checkout v5.0.0
mix deps.get
mix zig.get
mix compile
mix test
```

With global CLI (if installed):

```bash
zixir run examples/hello.zixir
zixir eval "engine.list_sum([1.0, 2.0, 3.0])"
```

## License

**Apache-2.0** — see [LICENSE](LICENSE).
