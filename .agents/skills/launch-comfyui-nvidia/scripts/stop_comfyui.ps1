# Stop ComfyUI server listening on port 8188
$conn = Get-NetTCPConnection -LocalPort 8188 -ErrorAction SilentlyContinue
if ($conn) {
    $pidToStop = $conn.OwningProcess
    Write-Host "Stopping ComfyUI process (PID: $pidToStop)..." -ForegroundColor Yellow
    Stop-Process -Id $pidToStop -Force
    Write-Host "ComfyUI process stopped successfully." -ForegroundColor Green
} else {
    Write-Host "No process found listening on port 8188." -ForegroundColor Yellow
}
