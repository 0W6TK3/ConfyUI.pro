---
name: comfyui-prompt-and-queue
description: >-
  Use this skill when the user asks to reverse-engineer prompts from an image, construct ComfyUI API prompt payloads, or interact with ComfyUI's REST API to queue, monitor, and retrieve generated images.
---

# ComfyUI Prompt Engineering & REST API Queueing

This skill details how to reverse-engineer detailed generative prompts from images, build ComfyUI API prompt payloads, submit execution jobs to ComfyUI's REST API, track progress, and retrieve output images programmatically.

---

## 1. ComfyUI REST API Endpoints

ComfyUI exposes a lightweight HTTP REST server on port `8188` (default: `http://127.0.0.1:8188`):

Endpoint | Method | Description
:--- | :--- | :---
`/system_stats` | `GET` | Reports GPU devices, total/free VRAM, and system RAM.
`/prompt` | `POST` | Queues a workflow execution payload.
`/queue` | `GET` | Returns list of currently pending and running jobs.
`/history` | `GET` | Returns execution history for all completed prompts.
`/history/{prompt_id}` | `GET` | Returns details, node execution outputs, and generated filenames for a specific prompt.
`/interrupt` | `POST` | Cancels the currently running execution.
`/view` | `GET` | Fetches image bytes (e.g. `?filename=foo.png&type=output`).

---

## 2. Image Reverse-Engineering Protocol

To recreate or style-transfer an image, structure prompts into clear visual components:

```text
[Quality Modifiers], [Central Subject & Materials], [Environment / Interior Scene], [Lighting & Atmosphere], [Color Gradients], [Camera / Render Style]
```

### Component Breakdown
1. **Core Subject**: State the physical object, geometry, and tactile material (*e.g., "an oval smooth glass bottle terrarium with a light wooden cap cork stopper, standing on a neutral beige textured fabric"*).
2. **Encapsulated Contents**: Detail the microcosm inside (*e.g., "inside the translucent glass egg flask is an encapsulated miniature fantasy galaxy landscape"*).
3. **Cosmic / Atmospheric Details**: (*e.g., "swirling cosmic nebula with deep purple, electric violet, vibrant cyan and turquoise glowing light, radiant central celestial sun star"*).
4. **Foreground / Micro Elements**: (*e.g., "serene turquoise reflective lake mirroring the starry cosmos, miniature lush green and magenta moss shoreline"*).
5. **Lighting & Bioluminescence**: (*e.g., "ethereal bioluminescence, volumetric cinematic lighting, specular glass highlights"*).
6. **Rendering Aesthetics**: (*e.g., "photorealistic macro photography, 8k resolution, crisp focus, octane render"*).

### Universal Negative Prompt Template
```text
ugly, deformed, noisy, blurry, low quality, distorted, extra limbs, bad proportions, watermark, signature, text, out of frame, cropped, cartoon, draft, grainy
```

---

## 3. UI Graph Format vs. API Prompt Format

ComfyUI has two distinct JSON formats:

- **UI Graph JSON** (`user/default/workflows/*.json`): Contains canvas positions, visual sizes, links array, groups, and node configurations. This is used by the frontend.
- **API Prompt JSON** (sent to `POST /prompt`): A flat dictionary of node definitions keyed by string IDs. Each node contains `"class_type"` and `"inputs"`. Connections reference other nodes as `["<node_id>", <slot_index>]`.

### Minimal API Prompt Payload Example

```json
{
  "prompt": {
    "1": {
      "class_type": "CheckpointLoaderSimple",
      "inputs": {
        "ckpt_name": "sd_xl_base_1.0.safetensors"
      }
    },
    "2": {
      "class_type": "CLIPTextEncode",
      "inputs": {
        "text": "masterpiece, ultra-detailed cosmic galaxy terrarium bottle, 8k",
        "clip": ["1", 1]
      }
    },
    "3": {
      "class_type": "CLIPTextEncode",
      "inputs": {
        "text": "ugly, blurry, low quality, distorted",
        "clip": ["1", 1]
      }
    },
    "4": {
      "class_type": "EmptyLatentImage",
      "inputs": {
        "width": 896,
        "height": 1152,
        "batch_size": 1
      }
    },
    "5": {
      "class_type": "KSampler",
      "inputs": {
        "seed": 42424242,
        "steps": 28,
        "cfg": 7.5,
        "sampler_name": "dpmpp_2m",
        "scheduler": "karras",
        "denoise": 1.0,
        "model": ["1", 0],
        "positive": ["2", 0],
        "negative": ["3", 0],
        "latent_image": ["4", 0]
      }
    },
    "6": {
      "class_type": "VAEDecode",
      "inputs": {
        "samples": ["5", 0],
        "vae": ["1", 2]
      }
    },
    "7": {
      "class_type": "SaveImage",
      "inputs": {
        "filename_prefix": "cosmic_bottle",
        "images": ["6", 0]
      }
    }
  }
}
```

---

## 4. Programmatic Job Submission & Polling

### Submitting via Python

```python
import urllib.request
import json
import time

API_URL = "http://127.0.0.1:8188"

# 1. Submit Prompt
req = urllib.request.Request(
    f"{API_URL}/prompt",
    data=json.dumps(payload).encode("utf-8"),
    headers={"Content-Type": "application/json"}
)
with urllib.request.urlopen(req) as resp:
    res_data = json.loads(resp.read().decode("utf-8"))
    prompt_id = res_data["prompt_id"]
    print(f"Submitted Prompt ID: {prompt_id}")

# 2. Poll Execution History
completed = False
while not completed:
    time.sleep(2)
    with urllib.request.urlopen(f"{API_URL}/history/{prompt_id}") as resp:
        history = json.loads(resp.read().decode("utf-8"))
        if prompt_id in history:
            completed = True
            outputs = history[prompt_id].get("outputs", {})
            for node_id, out in outputs.items():
                if "images" in out:
                    for img in out["images"]:
                        print(f"Generated Image: {img['filename']} (Subfolder: {img['subfolder']})")
```

### Submitting via PowerShell

```powershell
$payloadJson = Get-Content -Raw "prompt_payload.json"
$response = Invoke-RestMethod -Uri "http://127.0.0.1:8188/prompt" -Method Post -Body $payloadJson -ContentType "application/json"
$promptId = $response.prompt_id
Write-Host "Queued prompt: $promptId"

# Check history until finished
do {
    Start-Sleep -Seconds 2
    $history = Invoke-RestMethod -Uri "http://127.0.0.1:8188/history/$promptId"
} until ($history.$promptId)

Write-Host "Generation complete!"
```

---

## 5. Locating and Delivering Output Images

Generated images are automatically written to:
`C:\W6\_Progs\ComfyUI_windows_portable\ComfyUI\output\`

To deliver them to the user:
```powershell
Copy-Item "C:\W6\_Progs\ComfyUI_windows_portable\ComfyUI\output\<filename>.png" "<project_root>\<filename>.png" -Force
```
