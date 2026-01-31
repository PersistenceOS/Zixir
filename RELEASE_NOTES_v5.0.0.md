# Zixir v5.0.0 — Portable CLI, setup fixes, and redeploy

This release adds a **global/portable CLI** (run Zixir from any terminal path), **setup and docs fixes**, **signature test**, **test task sample**, and **PowerShell test script**. Redeploy of v5 with these fixes included.

---

## 1. Global / Portable CLI ✅

- **Run from any path** — After `mix release`, add `_build/dev/rel/zixir/bin` (or prod) to PATH. Run `zixir_run.bat` (Windows) or `zixir_run.sh` (Unix) with a path to a `.zixir` file from any directory.
- **Zixir.CLI** — `run_file(path)` and `run_file_from_argv()` for release eval; argv handling skips `--` so the path is correct.
- **Overlay scripts** — `rel/overlays/bin/zixir_run.bat` and `zixir_run.sh` included in the release.

---

## 2. Setup and docs fixes ✅

- **SETUP_GUIDE.md** — Added `mix zig.get` to Project Setup; aligned Zig version (0.15+); Windows install options (Scoop + installer link); note that Zigler can download Zig via `mix zig.get`.
- **README.md** — Link to SETUP_GUIDE for full install; “From a clone of the repo” before Setup commands.
- **docs/INDEX.md** — SETUP_GUIDE listed under Getting Started.

---

## 3. Signature test and test task ✅

- **test/zixir/signature_test.exs** — Unique test: hello-program signature (11.0), Zixir.run, parse→eval, idempotent eval; engine composition (dot_product + list_sum, etc.); parse/compile pipeline.
- **examples/test_task.zixir** — Sample that compiles and returns 22.0; used for portable CLI verification.
- **scripts/test-portable-cli.ps1** — PowerShell script: (1) mix zixir.run relative path, (2) mix zixir.run absolute path, (3) release `zixir_run.bat` from another directory. Checks both dev and prod release paths.

---

## 4. Release and compatibility

- **mix.exs** — Version 5.0.0; release overlays `rel/overlays` for portable runner scripts.
- **PowerShell 7.x** — Test script runs correctly; release `zixir_run.bat` works from any cwd when given full path to a `.zixir` file.

---

## Requirements

- **Elixir** 1.14+ / OTP 25+
- **Zig** 0.15+ (build-time; run `mix zig.get` after `mix deps.get`)
- **Python** 3.8+ *(optional)* for ML/specialist calls

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

Portable CLI (after `mix release`, add `bin/` to PATH):

```bash
# Windows
zixir_run.bat C:\path\to\script.zixir

# Unix/macOS
./zixir_run.sh /path/to/script.zixir
```

## License

**Apache-2.0** — see [LICENSE](LICENSE).
