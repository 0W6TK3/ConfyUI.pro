---
name: image-to-comfyui-workflow
description: >-
  Use this skill when the user provides an image or concept and asks to create a complete ComfyUI workflow (Text-to-Image or Image-to-Image), configure its generation parameters, and run or verify it in ComfyUI.
---

# Image-to-ComfyUI Workflow Generation & Execution

This skill provides end-to-end instructions for translating a reference image into an optimized ComfyUI workflow, configuring model and sampler parameters, deploying the workflow to ComfyUI, and executing generation with hardware acceleration.

---

## 1. Prerequisites & Environment

- **Portable ComfyUI Root**: `C:\W6\_Progs\ComfyUI_windows_portable`
- **Embedded Python**: `C:\W6\_Progs\ComfyUI_windows_portable\python_embeded\python.exe`
- **Models Directory**: `C:\W6\_Progs\ComfyUI_windows_portable\ComfyUI\models\checkpoints`
- **Default Checkpoint**: `sd_xl_base_1.0.safetensors`
- **User Workflows Directory**: `C:\W6\_Progs\ComfyUI_windows_portable\ComfyUI\user\default\workflows`
- **Output Directory**: `C:\W6\_Progs\ComfyUI_windows_portable\ComfyUI\output`
- **Web UI & API Endpoint**: `http://127.0.0.1:8188`

Ensure ComfyUI is running via `@skill:launch-comfyui-nvidia`. If port `8188` is not bound, start it:
```powershell
Start-Process -FilePath "cmd.exe" -ArgumentList "/k", "run_nvidia_gpu.bat" -WorkingDirectory "C:\W6\_Progs\ComfyUI_windows_portable"
```

---

## 2. Visual Analysis & Prompt Engineering

Deconstruct the reference image across six analytical dimensions:

1. **Central Subject**: Exact object, form, materials (e.g., *smooth egg-shaped glass flask, wooden stopper, cork base*).
2. **Encapsulated Content / Environment**: Internal scene details (e.g., *miniature terrarium, swirling nebula, mossy hills, glowing lake*).
3. **Lighting & Bioluminescence**: Volumetric light, specular reflections, neon/fluorescent accents (e.g., *celestial sun flare, glowing cyan water reflection, specular rim light*).
4. **Color Palette**: Dominant hues and gradients (e.g., *deep violet, celestial cyan, vibrant magenta, emerald moss, beige linen background*).
5. **Render & Photographic Style**: Macro photography, depth of field, 3D render engine (e.g., *8k octane render, crisp macro focus, photorealistic*).
6. **Negative Prompting**: Suppress artifacts without washing out contrast (e.g., *ugly, deformed, noisy, blurry, distorted, bad proportions, watermark, text*).

---

## 3. Selecting Workflow Architecture

Choose between two pipeline designs based on user intent:

### Option A: Text-to-Image (Full Resynthesis)
Best when generating fresh variations or higher-resolution interpretations inspired by the reference image.
- **Latent Node**: `EmptyLatentImage` (Resolution: `896x1152` for portrait, `1024x1024` for square, `1152x896` for landscape).
- **KSampler Denoise**: `1.0`
- **Sampler & Scheduler**: `dpmpp_2m` / `karras`
- **Steps & CFG**: `28-30` steps, `CFG 7.0 - 7.5`

### Option B: Image-to-Image (Direct Reference Variation)
Best when preserving the exact silhouette, composition, or texture of the uploaded image.
- Copy reference image to: `C:\W6\_Progs\ComfyUI_windows_portable\ComfyUI\input\<image_name>.png`
- **Latent Node**: `LoadImage` connected to `VAEEncode` (using checkpoint VAE).
- **KSampler Denoise**: `0.55 - 0.70` (lower preserves more original pixels; higher adds more AI details).

---

## 4. Workflow Generation Procedure

Generate the UI workflow JSON and save it in both the ComfyUI user template library and the project repository.

### Python Template for Text-to-Image Workflow Generation

```python
import json

workflow = {
  "last_node_id": 8,
  "last_link_id": 9,
  "nodes": [
    {
      "id": 1,
      "type": "CheckpointLoaderSimple",
      "pos": [60, 260],
      "size": [320, 100],
      "outputs": [
        {"name": "MODEL", "type": "MODEL", "links": [1]},
        {"name": "CLIP", "type": "CLIP", "links": [2, 3]},
        {"name": "VAE", "type": "VAE", "links": [4]}
      ],
      "widgets_values": ["sd_xl_base_1.0.safetensors"],
      "widgets_values_named": {"ckpt_name": "sd_xl_base_1.0.safetensors"}
    },
    {
      "id": 2,
      "type": "CLIPTextEncode",
      "pos": [450, 160],
      "size": [420, 180],
      "title": "Positive Prompt",
      "inputs": [{"name": "clip", "type": "CLIP", "link": 2}],
      "outputs": [{"name": "CONDITIONING", "type": "CONDITIONING", "links": [5]}],
      "widgets_values": [POS_PROMPT],
      "widgets_values_named": {"text": POS_PROMPT}
    },
    {
      "id": 3,
      "type": "CLIPTextEncode",
      "pos": [450, 400],
      "size": [420, 180],
      "title": "Negative Prompt",
      "inputs": [{"name": "clip", "type": "CLIP", "link": 3}],
      "outputs": [{"name": "CONDITIONING", "type": "CONDITIONING", "links": [6]}],
      "widgets_values": [NEG_PROMPT],
      "widgets_values_named": {"text": NEG_PROMPT}
    },
    {
      "id": 4,
      "type": "EmptyLatentImage",
      "pos": [450, 640],
      "size": [280, 110],
      "outputs": [{"name": "LATENT", "type": "LATENT", "links": [7]}],
      "widgets_values": [896, 1152, 1],
      "widgets_values_named": {"width": 896, "height": 1152, "batch_size": 1}
    },
    {
      "id": 5,
      "type": "KSampler",
      "pos": [930, 260],
      "size": [280, 280],
      "inputs": [
        {"name": "model", "type": "MODEL", "link": 1},
        {"name": "positive", "type": "CONDITIONING", "link": 5},
        {"name": "negative", "type": "CONDITIONING", "link": 6},
        {"name": "latent_image", "type": "LATENT", "link": 7}
      ],
      "outputs": [{"name": "LATENT", "type": "LATENT", "links": [8]}],
      "widgets_values": [42424242, "randomize", 28, 7.5, "dpmpp_2m", "karras", 1.0],
      "widgets_values_named": {"seed": 42424242, "steps": 28, "cfg": 7.5, "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0}
    },
    {
      "id": 6,
      "type": "VAEDecode",
      "pos": [1260, 260],
      "size": [210, 50],
      "inputs": [
        {"name": "samples", "type": "LATENT", "link": 8},
        {"name": "vae", "type": "VAE", "link": 4}
      ],
      "outputs": [{"name": "IMAGE", "type": "IMAGE", "links": [9]}],
    },
    {
      "id": 7,
      "type": "SaveImage",
      "pos": [1260, 360],
      "size": [320, 280],
      "inputs": [{"name": "images", "type": "IMAGE", "link": 9}],
      "widgets_values": ["generated_output"],
      "widgets_values_named": {"filename_prefix": "generated_output"}
    }
  ],
  "links": [
    [1, 1, 0, 5, 0, "MODEL"],
    [2, 1, 1, 2, 0, "CLIP"],
    [3, 1, 1, 3, 0, "CLIP"],
    [4, 1, 2, 6, 1, "VAE"],
    [5, 2, 0, 5, 1, "CONDITIONING"],
    [6, 3, 0, 5, 2, "CONDITIONING"],
    [7, 4, 0, 5, 3, "LATENT"],
    [8, 5, 0, 6, 0, "LATENT"],
    [9, 6, 0, 7, 0, "IMAGE"]
  ],
  "version": 0.4
}

# Save to ComfyUI user workflows
with open(r"C:\W6\_Progs\ComfyUI_windows_portable\ComfyUI\user\default\workflows\my_workflow.json", "w", encoding="utf-8") as f:
    json.dump(workflow, f, indent=2)
```

---

## 5. Submitting Job & Monitoring Output

Submit the prompt to the running ComfyUI instance via the API:

```python
import urllib.request
import json

prompt_payload = {
    "prompt": {
        "1": {"inputs": {"ckpt_name": "sd_xl_base_1.0.safetensors"}, "class_type": "CheckpointLoaderSimple"},
        "2": {"inputs": {"text": POS_PROMPT, "clip": ["1", 1]}, "class_type": "CLIPTextEncode"},
        "3": {"inputs": {"text": NEG_PROMPT, "clip": ["1", 1]}, "class_type": "CLIPTextEncode"},
        "4": {"inputs": {"width": 896, "height": 1152, "batch_size": 1}, "class_type": "EmptyLatentImage"},
        "5": {"inputs": {"seed": 42424242, "steps": 28, "cfg": 7.5, "sampler_name": "dpmpp_2m", "scheduler": "karras", "denoise": 1.0, "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["4", 0]}, "class_type": "KSampler"},
        "6": {"inputs": {"samples": ["5", 0], "vae": ["1", 2]}, "class_type": "VAEDecode"},
        "7": {"inputs": {"filename_prefix": "workflow_output", "images": ["6", 0]}, "class_type": "SaveImage"}
    }
}

req = urllib.request.Request("http://127.0.0.1:8188/prompt", data=json.dumps(prompt_payload).encode("utf-8"), headers={"Content-Type": "application/json"})
res = urllib.request.urlopen(req)
print("Queued prompt:", res.read().decode("utf-8"))
```

### Checking Output
Check `C:\W6\_Progs\ComfyUI_windows_portable\ComfyUI\output` for the generated `.png` image, and copy it to the project root for user review.
