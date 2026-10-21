# Check if ComfyUI is running on port 8188 and report status + GPU telemetry
$listenConn = Get-NetTCPConnection -LocalPort 8188 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1

if ($listenConn) {
    $procId = $listenConn.OwningProcess
    Write-Host "ComfyUI is RUNNING on port 8188 (PID: $procId)" -ForegroundColor Green
    Get-Process -Id $procId -ErrorAction SilentlyContinue | Select-Object Id, ProcessName, @{Name="MemoryMB"; Expression={[math]::Round($_.WorkingSet64 / 1MB, 2)}}, StartTime | Format-Table -AutoSize
    
    # Fetch live telemetry from system_stats API
    try {
        $stats = Invoke-RestMethod -Uri "http://127.0.0.1:8188/system_stats" -Method Get -TimeoutSec 3 -ErrorAction Stop
        $device = $stats.devices | Select-Object -First 1
        $totalVramMB = [math]::Round($device.vram_total / 1MB, 0)
        $freeVramMB = [math]::Round($device.vram_free / 1MB, 0)
        $totalRamMB = [math]::Round($stats.system.ram_total / 1MB, 0)
        $freeRamMB = [math]::Round($stats.system.ram_free / 1MB, 0)

        Write-Host "Hardware & Performance Telemetry:" -ForegroundColor Cyan
        Write-Host "  GPU Device : $($device.name)"
        Write-Host "  VRAM (Free/Total): $freeVramMB MB / $totalVramMB MB"
        Write-Host "  RAM  (Free/Total): $freeRamMB MB / $totalRamMB MB"
        Write-Host "  PyTorch / ComfyUI: $($stats.system.pytorch_version) / v$($stats.system.comfyui_version)"
    } catch {
        Write-Host "Server is initializing or API not responding yet." -ForegroundColor DarkGray
    }
} else {
    Write-Host "ComfyUI is NOT running on port 8188." -ForegroundColor Yellow
}

