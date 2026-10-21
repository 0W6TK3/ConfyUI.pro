# Check if ComfyUI is running on port 8188
$conn = Get-NetTCPConnection -LocalPort 8188 -ErrorAction SilentlyContinue
if ($conn) {
    Write-Host "ComfyUI is RUNNING on port 8188 (PID: $($conn.OwningProcess))" -ForegroundColor Green
    Get-Process -Id $conn.OwningProcess | Select-Object Id, ProcessName, @{Name="MemoryMB"; Expression={[math]::Round($_.WorkingSet64 / 1MB, 2)}}, StartTime
} else {
    Write-Host "ComfyUI is NOT running on port 8188." -ForegroundColor Yellow
}
