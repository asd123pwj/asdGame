# Restart / (re)start the Godot LSP server used by the VSCode Godot extension,
# so the final edits get re-indexed before a task is wrapped up.
#
# Two cases:
#   1) a headless LSP process with --lsp-port exists  -> restart it as-is (reuse its --path / --lsp-port)
#   2) none exists (it exited, or the LSP is only served by an open editor) ->
#      start one from .vscode/settings.json: godotTools.lsp.serverPort (default 6008)
#      + godotTools.editorPath.godot4
#
# Entry point: tools\godot_lsp_restart.bat (or run this script directly).
# NOTE: keep this file ASCII-only -- Windows PowerShell 5.1 reads BOM-less .ps1 as ANSI,
#       so non-ASCII text here would be mangled. Settings JSON may contain comments and
#       trailing commas, so values are read with regex instead of ConvertFrom-Json.

$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot                       # project root (parent of tools)
$settingsPath = Join-Path $root '.vscode\settings.json'
# The LSP is meant to outlive this script: give it its own output files, otherwise it would
# inherit our stdout/stderr handles and keep the caller (and any -Wait) hanging.
$lspOut = Join-Path $env:TEMP 'godot_lsp_out.log'
$lspErr = Join-Path $env:TEMP 'godot_lsp_err.log'

function Get-PortFromSettings {
    if (-not (Test-Path $settingsPath)) { return 6008 }
    $raw = Get-Content $settingsPath -Raw -Encoding UTF8
    $m = [regex]::Match($raw, '"godotTools\.lsp\.serverPort"\s*:\s*(\d+)')
    if ($m.Success) { return [int]$m.Groups[1].Value }
    return 6008
}

function Get-EditorExeFromSettings {
    if (-not (Test-Path $settingsPath)) { return '' }
    $raw = Get-Content $settingsPath -Raw -Encoding UTF8
    $m = [regex]::Match($raw, '"godotTools\.editorPath\.godot4"\s*:\s*"([^"]+)"')
    if ($m.Success) { return ($m.Groups[1].Value -replace '\\\\', '\') }
    return ''
}

# Godot needs a while to scan/import before it starts listening -> poll instead of one fixed sleep.
function Wait-Port([int]$port, [int]$seconds) {
    for ($i = 0; $i -lt $seconds; $i++) {
        Start-Sleep -Seconds 1
        $l = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -eq $port }
        if ($l) { return $l }
    }
    return $null
}

$targets = @(Get-CimInstance Win32_Process | Where-Object { $_.Name -like '*Godot*' -and $_.CommandLine -match '--lsp-port' })

if ($targets.Count -gt 0) {
    foreach ($p in $targets) {
        $c = $p.CommandLine
        if ($c[0] -eq [char]34) { $exe = $c.Substring(1, $c.IndexOf([char]34, 1) - 1) } else { $exe = ($c -split ' ')[0] }
        $pi = $c.IndexOf('--path ')
        $li = $c.IndexOf('--lsp-port ')
        if ($pi -lt 0 -or $li -lt 0) { Write-Host ("[LSP] PID {0}: cannot parse args, skipping" -f $p.ProcessId); continue }
        $rest = $c.Substring($pi + 7)
        if ($rest[0] -eq [char]34) { $proj = $rest.Substring(1, $rest.IndexOf([char]34, 1) - 1) } else { $proj = ($rest -split ' ')[0] }
        $port = (($c.Substring($li + 11)) -split ' ')[0]
        Write-Host ("[LSP] stopping PID {0} (port {1}, project {2})" -f $p.ProcessId, $port, $proj)
        Stop-Process -Id $p.ProcessId -Force
        Start-Sleep -Milliseconds 600
        Start-Process -FilePath $exe -ArgumentList @('--path', $proj, '--editor', '--headless', '--no-window', '--lsp-port', $port) -WindowStyle Hidden -RedirectStandardOutput $lspOut -RedirectStandardError $lspErr
        $listen = Wait-Port ([int]$port) 12
        if ($listen) { Write-Host ("[LSP] restarted: port {0} is listening (PID {1})" -f $port, ($listen | Select-Object -First 1).OwningProcess) }
        else { Write-Host ("[LSP] process restarted, but port {0} is not listening yet -- click Retry in VSCode" -f $port) }
    }
} else {
    $port = Get-PortFromSettings
    $exe = Get-EditorExeFromSettings
    if ($exe -eq '' -or -not (Test-Path $exe)) {
        Write-Host "[LSP] cannot find the Godot editor exe (see godotTools.editorPath.godot4 in .vscode/settings.json)"
        exit 1
    }
    Write-Host ("[LSP] no headless LSP process -> starting one from settings (port {0}, project {1})" -f $port, $root)
    Start-Process -FilePath $exe -ArgumentList @('--path', $root, '--editor', '--headless', '--no-window', '--lsp-port', $port) -WindowStyle Hidden -RedirectStandardOutput $lspOut -RedirectStandardError $lspErr
    $listen = Wait-Port ([int]$port) 15
    if ($listen) { Write-Host ("[LSP] up: port {0} is listening (PID {1})" -f $port, ($listen | Select-Object -First 1).OwningProcess) }
    else { Write-Host ("[LSP] process started, but port {0} is not listening yet (maybe another instance holds this project) -- click Retry in VSCode" -f $port) }
}
Write-Host ("[LSP] done (log: {0}; if VSCode does not reconnect, click Retry in the status bar)" -f $lspErr)
