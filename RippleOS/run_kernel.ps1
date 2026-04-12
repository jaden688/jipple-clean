param(
    [string]$BindHost = "127.0.0.1",
    [int]$Port = 8765,
    [switch]$Mock
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Get-JuliaBin {
    if ($env:JULIA_BIN -and (Test-Path $env:JULIA_BIN)) {
        return $env:JULIA_BIN
    }

    $command = Get-Command julia -ErrorAction SilentlyContinue
    if ($command -and $command.Source -notmatch "WindowsApps") {
        return $command.Source
    }

    return $null
}

$juliaBin = Get-JuliaBin
$useMock = $Mock.IsPresent -or -not $juliaBin

$env:RIPPLE_HOST = $BindHost
$env:RIPPLE_PORT = "$Port"

if ($useMock) {
    $env:RIPPLE_MOCK_KERNEL = "1"
    Write-Host "Launching RippleOS kernel in mock mode on ws://$BindHost`:$Port" -ForegroundColor Yellow
    Write-Host "Julia was not found. Set JULIA_BIN to a real julia.exe to use the VM." -ForegroundColor Yellow
} else {
    Remove-Item Env:RIPPLE_MOCK_KERNEL -ErrorAction SilentlyContinue
    $env:JULIA_BIN = $juliaBin
    Write-Host "Launching RippleOS kernel on ws://$BindHost`:$Port" -ForegroundColor Green
    Write-Host "Using Julia: $juliaBin" -ForegroundColor Green
}

Set-Location $scriptDir
python -u .\kernel_server.py
