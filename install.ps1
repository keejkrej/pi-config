#Requires -Version 5.1
<#
.SYNOPSIS
    pi-config installer for Windows.
    Automates the setup shown in IMG_1156 plus an Ollama cloud model provider.
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
    $OllamaUri = "https://$OllamaHost"
} else {
    $OllamaUri = $OllamaHost
}

$OllamaApiUrl = ($OllamaUri -replace '/v1$', '')

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
        $ver = pi --version 2>$null
        Write-Log "version: $ver"
        Write-Log "updating pi..."
        $LASTEXITCODE = 0
        pi update --self 2>$null
        if ($LASTEXITCODE -ne 0) {
            npm install -g --ignore-scripts $PI_PACKAGE
        }
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
    if (-not (Test-Path $AgentDir)) {
        New-Item -ItemType Directory -Path $AgentDir -Force | Out-Null
    }
    $target = Join-Path $AgentDir 'settings.json'
    Copy-Item -Path $SettingsFileSrc -Destination $target -Force
    Write-Log "installed settings: $target"
}

function Test-OllamaReachable {
    if (-not $env:OLLAMA_API_KEY) {
        return $false
    }
    try {
        $headers = @{ Authorization = "Bearer $env:OLLAMA_API_KEY" }
        $null = Invoke-RestMethod -Uri "$OllamaApiUrl/v1/models" -Method Get -Headers $headers -TimeoutSec 15 -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Pull-OllamaModel {
    if (-not $env:OLLAMA_API_KEY) {
        throw "OLLAMA_API_KEY environment variable is required for the Ollama cloud endpoint."
    }
    Write-Log "verifying Ollama cloud model: $OllamaModel"
    try {
        $headers = @{ Authorization = "Bearer $env:OLLAMA_API_KEY" }
        $response = Invoke-RestMethod -Uri "$OllamaApiUrl/v1/models" -Method Get -Headers $headers -TimeoutSec 30 -ErrorAction Stop
        $modelIds = $response.data | ForEach-Object { $_.id }
        if ($modelIds -contains $OllamaModel) {
            Write-Log "$OllamaModel is available in Ollama cloud"
        } else {
            Write-Log "warning: $OllamaModel was not found in the Ollama cloud model list; it may still be accessible"
        }
    } catch {
        Write-Log "warning: could not verify $OllamaModel in Ollama cloud"
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
            pi install "npm:$pkg" 2>$null
            Write-Log "installed npm:$pkg"
        } catch {
            Write-Log "warning: failed to install npm:$pkg (may already be installed or unavailable)"
        }
    }
}

function Show-NextSteps {
    Write-Log "setup complete"
    Write-Host ""
    Write-Host "Run 'pi' in this directory to start a session with the configured setup."
    Write-Host "Default model: $OllamaModel via Ollama cloud."
    Write-Host ""
    Write-Host "Make sure OLLAMA_API_KEY is set in your environment."
    Write-Host "To use a different default model, set OLLAMA_MODEL and re-run:"
    Write-Host "  `$env:OLLAMA_MODEL='kimi-k3'; `$env:OLLAMA_API_KEY='<key>'; .\install.ps1"
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
            throw "could not reach $OllamaApiUrl/v1/models with OLLAMA_API_KEY"
        }
        Pull-OllamaModel
    }
    Install-PiPackages
    Show-NextSteps
}

Main
