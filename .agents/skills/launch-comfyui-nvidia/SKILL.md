---
name: launch-comfyui-nvidia
description: >-
  Use this skill when the user asks to start, launch, run, check, or manage ComfyUI with NVIDIA GPU / CUDA acceleration on Windows.
---

# Launch ComfyUI with NVIDIA GPU Acceleration & Performance Optimization

This skill provides step-by-step instructions to start, monitor, verify, optimize, and manage ComfyUI running with NVIDIA GPU CUDA acceleration on Windows.

## 1. System Hardware Profile (Observed)

- **GPU:** NVIDIA GeForce RTX 4060 (Ada Lovelace architecture, ~8,187 MB VRAM)
- **Host RAM:** ~65,208 MB (64 GB)
- **PyTorch / CUDA:** `2.14.0+cu130` with `cudaMallocAsync` memory allocator
- **Runtime Offloading:**
  - `comfy-aimdo`: NVML pressure detection and DynamicVRAM enabled automatically.
  - `Pinned Memory`: Up to ~26 GB host RAM enabled for fast host-to-device tensor streaming.
  - `Async Offloading`: 2 streams active by default for concurrent weight transfer.

---

## 2. Performance Tuning Flags for RTX 40-Series

When starting ComfyUI or configuring extra arguments, use these flags to maximize generation speed and prevent VRAM exhaustion:

| Flag | Purpose | Recommended For |
|---|---|---|
| `--fast` | Enables `fp8_matrix_mult`, `cublas_ops`, `autotune`, and `fp16_accumulation` | Ada Lovelace (RTX 40-series) Tensor Core acceleration |
| `--fast-disk` | Enforces disk-backed dynamic loading and unpinned RAM offload | High-speed NVMe drives |
| `--async-offload 2` | Concurrent host-to-GPU transfer streams | Enabled by default on NVIDIA |
| `--reserve-vram 0.8` | Reserves 800MB VRAM for Windows desktop / browser display | Prevents UI stutter and CUDA OOM on 8GB VRAM |
| `--vram-headroom 0.5` | Maintains extra VRAM headroom for DynamicVRAM | Large workflows (SDXL, Flux) on 8GB cards |

---

## 3. Directory Structure & Entry Points

Installation directory:
`C:\W6\_Progs\ComfyUI_windows_portable`

- **Embedded Python:** `.\python_embeded\python.exe`
- **Entry script:** `ComfyUI\main.py`
- **Default Batch:** `run_nvidia_gpu.bat`

---

## 4. Helper Scripts (`.agents/skills/launch-comfyui-nvidia/scripts/`)

### A. Launch Interactively (User-Facing)
Script: [launch_interactive.ps1](./scripts/launch_interactive.ps1)
- Performs a pre-flight check so it won't crash on port collision if ComfyUI is already running.
- Accepts `-ExtraArgs` for performance flags (e.g. `-ExtraArgs "--fast"`).
- Automatically waits for server readiness via `wait_ready.ps1`.

```powershell
# Standard launch
.\.agents\skills\launch-comfyui-nvidia\scripts\launch_interactive.ps1

# High-performance launch (RTX 40-series)
.\.agents\skills\launch-comfyui-nvidia\scripts\launch_interactive.ps1 -ExtraArgs "--fast"
```

### B. Launch Headless / Background (Agent Managed)
When running headless in the background:
```powershell
cmd.exe /c "cd /d C:\W6\_Progs\ComfyUI_windows_portable && .\python_embeded\python.exe -s ComfyUI\main.py --windows-standalone-build"
```

### C. Wait for Server Readiness
Script: [wait_ready.ps1](./scripts/wait_ready.ps1)
Blocks until the ComfyUI web API is responsive, reporting elapsed time and initial VRAM stats:
```powershell
.\.agents\skills\launch-comfyui-nvidia\scripts\wait_ready.ps1 -TimeoutSeconds 30
```

### D. Verification & Status Telemetry
Script: [check_status.ps1](./scripts/check_status.ps1)
- Identifies listening process on port `8188`.
- Queries `http://127.0.0.1:8188/system_stats` for real-time VRAM/RAM allocation and GPU device status.

```powershell
.\.agents\skills\launch-comfyui-nvidia\scripts\check_status.ps1
```

### E. Stop ComfyUI
Script: [stop_comfyui.ps1](./scripts/stop_comfyui.ps1)
- Filters unique process IDs across all active TCP connections on port 8188.
- Terminates cleanly without duplicate-process exceptions.

```powershell
.\.agents\skills\launch-comfyui-nvidia\scripts\stop_comfyui.ps1
```

---

## 5. Web Interface and APIs

- **Web GUI:** [http://127.0.0.1:8188](http://127.0.0.1:8188)
- **Telemetry API:** `http://127.0.0.1:8188/system_stats`
- **Execution Queue API:** `http://127.0.0.1:8188/queue`

