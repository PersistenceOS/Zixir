#!/usr/bin/env sh
# Run a .zixir file by path from any working directory (portable CLI).
# Usage: zixir_run.sh /path/to/file.zixir
# Add this script's directory to PATH after building the release (mix release).

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
exec "$SCRIPT_DIR/zixir" eval "Zixir.CLI.run_file_from_argv()" -- "$@"
