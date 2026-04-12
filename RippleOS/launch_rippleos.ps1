param(
    [string]$BindHost = "127.0.0.1",
    [int]$PreferredKernelPort = 8765,
    [int]$PreferredUiPort = 5173,
    [switch]$Mock
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$kernelScript = Join-Path $scriptDir "run_kernel.ps1"
$uiScript = Join-Path $scriptDir "run_ui.ps1"

function Test-PortAvailable {
    param([int]$Port)

    $listener = $null
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
        $listener.Start()
        return $true
    } catch {
        return $false
    } finally {
        if ($listener) {
            $listener.Stop()
        }
    }
}

function Get-FreePort {
    param([int]$StartPort)

    for ($port = $StartPort; $port -lt ($StartPort + 25); $port++) {
        if (Test-PortAvailable -Port $port) {
            return $port
        }
    }

    throw "Could not find a free port starting at $StartPort."
}

$kernelPort = Get-FreePort -StartPort $PreferredKernelPort
$uiPort = Get-FreePort -StartPort $PreferredUiPort

$kernelArgs = @(
    "-ExecutionPolicy", "Bypass",
    "-NoExit",
    "-File", $kernelScript,
    "-BindHost", $BindHost,
    "-Port", "$kernelPort"
)

if ($Mock) {
    $kernelArgs += "-Mock"
}

$uiArgs = @(
    "-ExecutionPolicy", "Bypass",
    "-NoExit",
    "-File", $uiScript,
    "-UiHost", $BindHost,
    "-UiPort", "$uiPort",
    "-KernelHost", $BindHost,
    "-KernelPort", "$kernelPort"
)

Start-Process powershell.exe -ArgumentList $kernelArgs | Out-Null
Start-Sleep -Milliseconds 800
Start-Process powershell.exe -ArgumentList $uiArgs | Out-Null

Write-Host "RippleOS launcher started." -ForegroundColor Green
Write-Host "Kernel websocket: ws://$BindHost`:$kernelPort"
Write-Host "UI URL: http://$BindHost`:$uiPort"
Write-Host "Use -Mock to force the fallback kernel even when Julia is installed."
