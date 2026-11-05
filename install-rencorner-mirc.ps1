<#
  RenCorner mIRC setup for a new Windows PC
  -----------------------------------------
  1. Put this file and rencorner.mrc in the same folder (e.g. Downloads).
  2. Right-click this file > "Run with PowerShell"
     (or in PowerShell:  powershell -ExecutionPolicy Bypass -File .\install-rencorner-mirc.ps1)

  What it does:
    - Installs official mIRC with winget (skips if already installed)
    - Copies rencorner.mrc into your mIRC folder (%APPDATA%\mIRC)
    - Registers the script in mirc.ini so it loads automatically
    - Starts mIRC. First launch asks for your NickServ password and channel key once.
#>

$ErrorActionPreference = 'Stop'
$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$script  = Join-Path $here 'rencorner.mrc'
$mircDir = Join-Path $env:APPDATA 'mIRC'
$ini     = Join-Path $mircDir 'mirc.ini'

function Say($msg) { Write-Host "[RenCorner] $msg" -ForegroundColor Cyan }

if (-not (Test-Path $script)) { throw "rencorner.mrc not found next to this installer ($here)." }

# --- 1. Install mIRC -------------------------------------------------
$mircExe = @(
  "$env:ProgramFiles\mIRC\mirc.exe",
  "${env:ProgramFiles(x86)}\mIRC\mirc.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $mircExe) {
  if (Get-Command winget -ErrorAction SilentlyContinue) {
    Say 'Installing mIRC with winget...'
    winget install --id mIRC.mIRC -e --accept-source-agreements --accept-package-agreements
    $mircExe = @("$env:ProgramFiles\mIRC\mirc.exe","${env:ProgramFiles(x86)}\mIRC\mirc.exe") |
               Where-Object { Test-Path $_ } | Select-Object -First 1
  }
  if (-not $mircExe) {
    Say 'Could not install automatically. Install mIRC from https://www.mirc.com/get.html, then run this again.'
    Start-Process 'https://www.mirc.com/get.html'
    exit 1
  }
} else { Say "mIRC already installed: $mircExe" }

# --- 2. Make sure mIRC is closed (it rewrites mirc.ini on exit) ------
if (Get-Process mirc -ErrorAction SilentlyContinue) {
  Say 'Close mIRC, then press Enter to continue...'
  Read-Host | Out-Null
}

# --- 3. Create mIRC's folder / ini on first run ----------------------
if (-not (Test-Path $ini)) {
  Say 'Starting mIRC once to create its settings. Close mIRC when the window opens, then press Enter.'
  Start-Process $mircExe
  Read-Host | Out-Null
}
New-Item -ItemType Directory -Force -Path $mircDir | Out-Null
Copy-Item $script (Join-Path $mircDir 'rencorner.mrc') -Force
Say "Copied rencorner.mrc to $mircDir"

# --- 4. Register the script under [rfiles] in mirc.ini --------------
if (Test-Path $ini) {
  $lines = [System.Collections.Generic.List[string]](Get-Content $ini)
  if ($lines -match '(?i)rencorner\.mrc') {
    Say 'Script already registered in mirc.ini.'
  } else {
    $start = $lines.FindIndex({ param($l) $l -match '^\[rfiles\]' })
    if ($start -lt 0) {
      $lines.Add('[rfiles]'); $lines.Add('n0=rencorner.mrc')
    } else {
      $end = $start + 1; $max = -1
      while ($end -lt $lines.Count -and $lines[$end] -notmatch '^\[') {
        if ($lines[$end] -match '^n(\d+)=') { $max = [Math]::Max($max, [int]$matches[1]) }
        $end++
      }
      $lines.Insert($end, "n$($max + 1)=rencorner.mrc")
    }
    Copy-Item $ini "$ini.bak" -Force
    Set-Content -Path $ini -Value $lines -Encoding Default
    Say 'Registered script in mirc.ini (backup saved as mirc.ini.bak).'
  }
} else {
  Say 'mirc.ini not found. After mIRC opens, type:  /load -rs rencorner.mrc'
}

# --- 5. Launch -------------------------------------------------------
Say 'Starting mIRC. Enter your NickServ password and channel key when asked (first run only).'
Start-Process $mircExe
