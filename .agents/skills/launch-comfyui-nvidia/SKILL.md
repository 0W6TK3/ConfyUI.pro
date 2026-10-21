---
name: launch-comfyui-nvidia
description: >-
  Use this skill when the user asks to start, launch, run, check, or manage ComfyUI with NVIDIA GPU / CUDA acceleration on Windows.
---

# Launch ComfyUI with NVIDIA GPU Acceleration

This skill provides step-by-step instructions to start, monitor, verify, and manage ComfyUI running with NVIDIA GPU CUDA acceleration.

## 1. Directory Structure and Launcher

The standard portable installation is located at:
`C:\W6\_Progs\ComfyUI_windows_portable`

Key executables and entry points:
- Embedded Python: `.\python_embeded\python.exe`
- Main script: `ComfyUI\main.py`
- NVIDIA launch script: `run_nvidia_gpu.bat`

Default command executed by `run_nvidia_gpu.bat`:
```cmd
.\python_embeded\python.exe -s ComfyUI\main.py --windows-standalone-build
```

## 2. Launching ComfyUI  

Depending on how the user wants to run ComfyUI:

### Option A: Interactive Terminal Window (User-Facing)
Opens a separate Command Prompt window on the desktop so the user can see real-time generation output and server logs.

Helper script: [launch_interactive.ps1](./scripts/launch_interactive.ps1)
```powershell
Start-Process -FilePath "cmd.exe" -ArgumentList "/k", "run_nvidia_gpu.bat" -WorkingDirectory "C:\W6\_Progs\ComfyUI_windows_portable"
```

### Option B: Background Server (Headless / Agent Managed)
Run the process in the background from the root directory:
```powershell
cmd.exe /c "cd /d C:\W6\_Progs\ComfyUI_windows_portable && .\python_embeded\python.exe -s ComfyUI\main.py --windows-standalone-build"
```

## 3. Verification & Health Check

Helper script: [check_status.ps1](./scripts/check_status.ps1)

### Check Port 8188 Binding
ComfyUI web server listens on port `8188` by default:
```powershell
Get-NetTCPConnection -LocalPort 8188 -ErrorAction SilentlyContinue | Select-Object LocalAddress, LocalPort, State, OwningProcess
```

### Confirm NVIDIA CUDA Detection
Inspect server output for:
- `[INFO] Device: cuda:0 NVIDIA <GPU Name> : cudaMallocAsync`
- `[INFO] Total VRAM <Amount> MB`
- `[INFO] To see the GUI go to: http://127.0.0.1:8188`

### Web GUI Access
Open the web browser to:
[http://127.0.0.1:8188](http://127.0.0.1:8188)

## 4. Stopping and Managing the Service

Helper script: [stop_comfyui.ps1](./scripts/stop_comfyui.ps1)

To find and stop the running ComfyUI process:
```powershell
$conn = Get-NetTCPConnection -LocalPort 8188 -ErrorAction SilentlyContinue
if ($conn) {
    Stop-Process -Id $conn.OwningProcess -Force
}
```
