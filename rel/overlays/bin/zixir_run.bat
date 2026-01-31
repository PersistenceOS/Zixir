@echo off
REM Run a .zixir file by path from any working directory (portable CLI).
REM Usage: zixir_run.bat C:\path\to\file.zixir
REM Add this script's directory to PATH after building the release (mix release).

set SCRIPT_DIR=%~dp0
"%SCRIPT_DIR%zixir.bat" eval "Zixir.CLI.run_file_from_argv()" -- %*
