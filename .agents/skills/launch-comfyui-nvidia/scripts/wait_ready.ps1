param(
    [int]$TimeoutSeconds = 30
)

# Wait until ComfyUI server is fully initialized and ready to accept requests
Write-Host "Waiting for ComfyUI to become ready on http://127.0.0.1:8188 (up to $TimeoutSeconds s)..." -ForegroundColor Cyan

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$ready = $false

while ($sw.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
    try {
        $stats = Invoke-RestMethod -Uri "http://127.0.0.1:8188/system_stats" -Method Get -TimeoutSec 2 -ErrorAction Stop
        if ($stats) {
            $device = $stats.devices | Select-Object -First 1
            $freeVramMB = [math]::Round($device.vram_free / 1MB, 0)
            $totalVramMB = [math]::Round($device.vram_total / 1MB, 0)
            $elapsedSec = [math]::Round($sw.Elapsed.TotalSeconds, 1)

            Write-Host "ComfyUI is READY after ${elapsedSec}s!" -ForegroundColor Green
            Write-Host "  GPU Device : $($device.name)"
            Write-Host "  VRAM (Free): $freeVramMB MB / $totalVramMB MB"
            Write-Host "  Web GUI    : http://127.0.0.1:8188"
            $ready = $true
            break
        }
    } catch {
        Start-Sleep -Milliseconds 800
    }
}

$sw.Stop()

if (-not $ready) {
    Write-Host "Timed out waiting for ComfyUI on port 8188 after $TimeoutSeconds seconds." -ForegroundColor Red
    exit 1
}
exit 0
