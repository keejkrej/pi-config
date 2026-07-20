#Requires -Version 5.1
<#
.SYNOPSIS
    pi-config installer for Windows.
    Automates the setup shown in IMG_1156 plus an Ollama local model provider.
#>
[CmdletBinding()]
param(
    [string]$OllamaHost = ($env:OLLAMA_HOST -replace 'https?://', ''),
    [string]$OllamaModel = ($env:OLLAMA_MODEL),
    [switch]$SkipOllama
)

$ErrorActionPreference = 'Stop'

$PI_PACKAGE = '@earendil-works/pi-coding-agent'

if (-not $OllamaHost) { $OllamaHost = 'ollama.com' }
if (-not $OllamaModel) { $OllamaModel = 'kimi-k2.7-code' }

if ($OllamaHost -notmatch '^https?://') {
    $OllamaUri = "http://$OllamaHost"
} else {
    $OllamaUri = $OllamaHost
}

$RepoDir = $PSScriptRoot
if (-not $RepoDir) { $RepoDir = Get-Location }
$AgentDir = if ($env:PI_CODING_AGENT_DIR) { $env:PI_CODING_AGENT_DIR } else { Join-Path $env:USERPROFILE '.pi' 'agent' }
$ModelsFileSrc = Join-Path $RepoDir 'models.json'
$SettingsFileSrc = Join-Path $RepoDir '.pi' 'settings.json'

function Write-Log {
    param([string]$Message)
    Write-Host "[pi-config] $Message"
}

function Test-Command {
    param([string]$Name)
    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Require-Node {
    if (-not (Test-Command node) -or -not (Test-Command npm)) {
        throw "Node.js and npm are required. Install them from https://nodejs.org/ and re-run this script."
    }
    Write-Log "node $(node --version), npm $(npm --version)"
}

function Install-PiCli {
    if (Test-Command pi) {
        Write-Log "pi already installed."
        try {
            $ver = pi --version 2>$null
            Write-Log "version: $ver"
        } catch {}
        Write-Log "updating pi..."
        pi update --self 2>$null || npm install -g --ignore-scripts $PI_PACKAGE
    } else {
        Write-Log "installing pi..."
        npm install -g --ignore-scripts $PI_PACKAGE
    }
}

function Ensure-AgentDir {
    if (-not (Test-Path $AgentDir)) {
        New-Item -ItemType Directory -Path $AgentDir -Force | Out-Null
    }
    Write-Log "Pi agent dir: $AgentDir"
}

function Install-ModelsJson {
    if (-not (Test-Path $ModelsFileSrc)) {
        throw "models.json source not found at $ModelsFileSrc"
    }
    $target = Join-Path $AgentDir 'models.json'
    Copy-Item -Path $ModelsFileSrc -Destination $target -Force
    Write-Log "installed $target"
}

function Install-ProjectSettings {
    $targetDir = Join-Path $RepoDir '.pi'
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    $target = Join-Path $targetDir 'settings.json'
    Copy-Item -Path $SettingsFileSrc -Destination $target -Force
    Write-Log "installed project settings: $target"
}

function Test-OllamaReachable {
    if (-not $env:OLLAMA_API_KEY) {
        return $false
    }
    try {
        $headers = @{ Authorization = "Bearer $env:OLLAMA_API_KEY" }
        $null = Invoke-RestMethod -Uri "$OllamaUri/" -Method Get -Headers $headers -TimeoutSec 5 -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Pull-OllamaModel {
    if (-not $env:OLLAMA_API_KEY) {
        throw "OLLAMA_API_KEY environment variable is required for the ollama.com cloud endpoint."
    }
        Write-Log "requesting Ollama cloud model: $OllamaModel"
        $headers = @{ Authorization = "Bearer $env:OLLAMA_API_KEY" }
        $body = @{ name = $OllamaModel } | ConvertTo-Json -Compress
        $pullUri = if ($OllamaUri -match '/v1$') { "$OllamaUri/models/$OllamaModel/pull" } else { "$OllamaUri/api/pull" }
    try {
        # Streamed response; we just kick it off and wait for it to complete.
        $null = Invoke-RestMethod -Uri $pullUri -Method Post -Headers $headers -Body $body -TimeoutSec 300 -ErrorAction Stop
        Write-Log "pull requested for $OllamaModel"
    } catch {
        # Some providers return non-stream success shapes; treat as warning rather than fatal.
        Write-Log "warning: pull API call returned an error/warning: $_"
    }
}

function Install-PiPackages {
    Write-Log "installing pi packages..."
    try {
        pi update --all 2>$null
    } catch {
        Write-Log "warning: pi update --all failed, will try individual installs"
    }
    $packages = @(
        '@plannotator/pi-extension',
        '@ff-labs/pi-fff',
        'pi-web-extension',
        'pi-cursor-sdk',
        'pi-thinking-steps',
        'pi-mcp-adapter',
        '@sampfp/pi-essentials'
    )
    foreach ($pkg in $packages) {
        try {
            pi install $pkg 2>$null
            Write-Log "installed $pkg"
        } catch {
            Write-Log "warning: failed to install $pkg (may already be installed or unavailable)"
        }
    }
}

function Show-NextSteps {
    Write-Log "setup complete"
    Write-Host ""
    Write-Host "Run 'pi' in this directory to start a session with the configured setup."
    Write-Host "Default model: $OllamaModel via Ollama cloud (ollama.com)."
    Write-Host ""
    Write-Host "Make sure OLLAMA_API_KEY is set in your environment."
    Write-Host "To use a different default model, set OLLAMA_MODEL and re-run:"
    Write-Host "  `$env:OLLAMA_MODEL='kimi-k2.7-code'; `$env:OLLAMA_API_KEY='<key>'; .\install.ps1"
}

function Main {
    Require-Node
    Install-PiCli
    Ensure-AgentDir
    Install-ModelsJson
    Install-ProjectSettings
    if (-not $env:OLLAMA_API_KEY) {
        throw "OLLAMA_API_KEY environment variable is required. Set it before running this script."
    }
    if (-not $SkipOllama) {
        if (-not (Test-OllamaReachable)) {
            Write-Log "warning: could not reach $OllamaUri with OLLAMA_API_KEY; continuing anyway"
        }
        Pull-OllamaModel
    }
    Install-PiPackages
    Show-NextSteps
}

Main
