# Apply pi configuration from this repo (Windows / PowerShell).
# Copies mcp.json, AGENTS.md and the reviewer agent, and registers the subagent
# extension bundled with pi in settings.json so the reviewer can be spawned.
[CmdletBinding()]
param(
  [string]$PiDir = (Join-Path $HOME ".pi\agent")
)

$ErrorActionPreference = "Stop"
$Here = $PSScriptRoot

function Copy-File($Src, $Dest) {
  $destParent = Split-Path -Parent $Dest
  if (-not (Test-Path $destParent)) { New-Item -ItemType Directory -Path $destParent -Force | Out-Null }

  if (-not (Test-Path $Src)) {
    Write-Host "!! source missing: $Src" -ForegroundColor Red
    throw "source path does not exist: $Src"
  }
  $leaf = Split-Path -Leaf $Dest
  if (Test-Path $Dest) {
    if ((Get-FileHash $Src).Hash -eq (Get-FileHash $Dest).Hash) {
      Write-Host "    unchanged $leaf"
      return
    }
    $backup = "$Dest.bak.$([int][double]::Parse((Get-Date -UFormat %s)))"
    Move-Item $Dest $backup -Force
    Write-Host "    backed up existing $leaf"
  }
  Copy-Item $Src $Dest -Force
  Write-Host "    copied $leaf"
}

# The bundled extension lives under a version-pinned path, so resolve it from the
# installed version every time and replace any stale entry.
function Register-SubagentExtension {
  $versionFile = Join-Path $PiDir "install\current-version"
  if (-not (Test-Path $versionFile)) {
    Write-Host "!! $versionFile not found; add the subagent extension to `"extensions`" in $PiDir\settings.json by hand" -ForegroundColor Yellow
    return
  }
  $version = ((Get-Content -Raw $versionFile) -replace '\s', '')
  $entry = "install/releases/$version/node_modules/@earendil-works/pi-coding-agent/examples/extensions/subagent/index.ts"
  if (-not (Test-Path (Join-Path $PiDir $entry))) {
    Write-Host "!! bundled subagent extension not found at $PiDir\$entry" -ForegroundColor Yellow
    return
  }
  $settingsFile = Join-Path $PiDir "settings.json"
  $settings = New-Object PSObject
  if (Test-Path $settingsFile) { $settings = Get-Content -Raw $settingsFile | ConvertFrom-Json }
  $existing = @()
  if ($settings.PSObject.Properties['extensions']) { $existing = @($settings.extensions) }
  $filtered = @($existing | Where-Object { $_ -notlike '*examples/extensions/subagent/*' })
  $settings | Add-Member -NotePropertyName extensions -NotePropertyValue @($filtered + $entry) -Force
  [System.IO.File]::WriteAllText($settingsFile, (($settings | ConvertTo-Json -Depth 10) + "`n"))
  Write-Host "    registered subagent extension (pi $version) in settings.json"
}

Write-Host "==> Applying pi config from $Here -> $PiDir"
if (-not (Test-Path $PiDir)) { New-Item -ItemType Directory -Path $PiDir -Force | Out-Null }
$agentsDest = Join-Path $PiDir "agents"
if (-not (Test-Path $agentsDest)) { New-Item -ItemType Directory -Path $agentsDest -Force | Out-Null }

Copy-File (Join-Path $Here "mcp.json") (Join-Path $PiDir "mcp.json")
Copy-File (Join-Path $Here "AGENTS.md") (Join-Path $PiDir "AGENTS.md")
$agentsDir = Join-Path $Here "agents"
if (Test-Path $agentsDir) {
  Get-ChildItem -Path $agentsDir -Filter *.md | ForEach-Object {
    Copy-File $_.FullName (Join-Path $agentsDest $_.Name)
  }
}
Register-SubagentExtension

Write-Host ""
Write-Host "==> Done. Installed:"
Write-Host "    $PiDir\mcp.json         <- $Here\mcp.json"
Write-Host "    $PiDir\AGENTS.md        <- $Here\AGENTS.md"
Write-Host "    $PiDir\agents\*.md      <- $Here\agents"
Write-Host "    $PiDir\settings.json    `"extensions`" entry for the bundled subagent extension"
Write-Host ""
Write-Host "==> Notes:"
Write-Host "    Sign in to your providers in pi."
Write-Host "    mobbin runs through mcp-remote: the first time pi starts it, a browser opens"
Write-Host "    for the Mobbin login; the token is then shared by every agent via ~/.mcp-auth."
Write-Host "    The extension path is pinned to the installed pi version: re-run after a pi upgrade."
Write-Host "    Nothing is linked: re-run this script after editing files here."
Write-Host ""
Write-Host "==> Verify with:"
Write-Host "    pi mcp list"
