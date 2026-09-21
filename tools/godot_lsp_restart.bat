@echo off
rem Restart / start the Godot LSP server (logic lives in godot_lsp_restart.ps1 next to this file)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0godot_lsp_restart.ps1"
