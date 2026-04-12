param(
    [string]$UiHost = "127.0.0.1",
    [int]$UiPort = 5173,
    [string]$KernelHost = "127.0.0.1",
    [int]$KernelPort = 8765
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$uiDir = Join-Path $scriptDir "ui"
$env:VITE_KERNEL_URL = "ws://$KernelHost`:$KernelPort"

Write-Host "Launching RippleOS UI on http://$UiHost`:$UiPort" -ForegroundColor Cyan
Write-Host "Kernel URL: $env:VITE_KERNEL_URL" -ForegroundColor Cyan

Set-Location $uiDir
npm run dev -- --host $UiHost --port $UiPort
