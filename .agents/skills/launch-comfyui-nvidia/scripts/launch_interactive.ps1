param(
    [switch]$Force,
    [string]$ExtraArgs = ""
)

# 1. Pre-flight check: Is ComfyUI already active?
$listenConn = Get-NetTCPConnection -LocalPort 8188 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
if ($listenConn -and (-not $Force)) {
    Write-Host "ComfyUI is ALREADY running on port 8188 (PID: $($listenConn.OwningProcess))." -ForegroundColor Yellow
    Write-Host "Use http://127.0.0.1:8188 or run with -Force to start anyway." -ForegroundColor DarkGray
    exit 0
}

# 2. Launch interactive terminal window
$workDir = "C:\W6\_Progs\ComfyUI_windows_portable"
$launchCmd = ".\python_embeded\python.exe -s ComfyUI\main.py --windows-standalone-build"
if ($ExtraArgs) {
    $launchCmd += " $ExtraArgs"
}

Write-Host "Starting ComfyUI with NVIDIA GPU acceleration..." -ForegroundColor Cyan
Start-Process -FilePath "cmd.exe" -ArgumentList "/k", $launchCmd -WorkingDirectory $workDir

# 3. Wait for readiness
$waitScript = Join-Path $PSScriptRoot "wait_ready.ps1"
if (Test-Path $waitScript) {
    & $waitScript -TimeoutSeconds 35
}

