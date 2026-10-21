# Stop ComfyUI server listening on port 8188
$conns = Get-NetTCPConnection -LocalPort 8188 -ErrorAction SilentlyContinue
if ($conns) {
    $pidsToStop = $conns | Select-Object -ExpandProperty OwningProcess -Unique
    foreach ($procId in $pidsToStop) {
        if ($procId -gt 0) {
            Write-Host "Stopping ComfyUI process (PID: $procId)..." -ForegroundColor Yellow
            Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host "ComfyUI stopped successfully." -ForegroundColor Green
} else {
    Write-Host "No process found listening on port 8188." -ForegroundColor Yellow
}

