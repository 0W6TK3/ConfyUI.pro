---
name: comfyui-workflow-builder
description: >-
  Use this skill when the user asks to generate, inspect, edit, or customize ComfyUI graph JSON workflow files, configure nodes (KSampler, CheckpointLoader, CLIP, VAE), manage link connections, or troubleshoot workflow structure.
---

# ComfyUI Workflow Graph Builder & Editor

This skill provides comprehensive documentation and procedural guides for creating, modifying, inspecting, and validating ComfyUI workflow JSON files (the format saved and loaded in the ComfyUI web interface).

---

## 1. ComfyUI Graph Schema Anatomy

A ComfyUI workflow JSON file has the following top-level architecture:

```json
{
  "id": "optional-uuid",
  "revision": 0,
  "last_node_id": 15,
  "last_link_id": 20,
  "nodes": [ ... ],
  "links": [ ... ],
  "groups": [ ... ],
  "config": {},
  "extra": { "ds": { "scale": 1.0, "offset": [0, 0] } },
  "version": 0.4
}
```

### The Node Object Structure
Every node inside `"nodes"` defines an operation in the execution graph:

```json
{
  "id": 12,
  "type": "KSampler",
  "pos": [1030, 270],
  "size": [270, 270],
  "flags": {},
  "order": 5,
  "mode": 0,
  "inputs": [
    { "name": "model", "type": "MODEL", "link": 38 },
    { "name": "positive", "type": "CONDITIONING", "link": 33 },
    { "name": "negative", "type": "CONDITIONING", "link": 34 },
    { "name": "latent_image", "type": "LATENT", "link": 35 }
  ],
  "outputs": [
    { "name": "LATENT", "type": "LATENT", "links": [36] }
  ],
  "widgets_values": [508307759591242, "randomize", 25, 7, "dpmpp_2m", "karras", 1.0],
  "widgets_values_named": {
    "seed": 508307759591242,
    "control_after_generate": "randomize",
    "steps": 25,
    "cfg": 7.0,
    "sampler_name": "dpmpp_2m",
    "scheduler": "karras",
    "denoise": 1.0
  }
}
```

### The Link Array Structure
Links connect an output slot of one node to an input slot of another:
```json
[link_id, source_node_id, source_slot_index, target_node_id, target_slot_index, "DATA_TYPE"]
```

> [!IMPORTANT]
> - `source_slot_index` and `target_slot_index` are **0-indexed**.
> - Each input slot can only have **one** incoming link.
> - An output slot can have **multiple** links (fan-out). In the node's `"outputs"` list, the `"links"` field is an array of all active link IDs.

---

## 2. Core Nodes Reference & Parameter Mapping

### 1. `KSampler`
Drives diffusion sampling.

- **Inputs**:
  - `model` (MODEL)
  - `positive` (CONDITIONING)
  - `negative` (CONDITIONING)
  - `latent_image` (LATENT)
- **Outputs**: `LATENT`
- **Widget Values (`widgets_values`)**:
  `[seed, control_after_generate, steps, cfg, sampler_name, scheduler, denoise]`
  - `seed` (int): e.g., `42424242`
  - `control_after_generate` (str): `"fixed"`, `"increment"`, `"decrement"`, `"randomize"`
  - `steps` (int): Typical range `20 - 35` for SDXL
  - `cfg` (float): Classifier-Free Guidance, typically `6.5 - 8.0`
  - `sampler_name` (str): `"euler"`, `"euler_ancestral"`, `"heun"`, `"dpm_2"`, `"dpmpp_2m"`, `"dpmpp_sde"`, `"ddim"`, `"uni_pc"`
  - `scheduler` (str): `"normal"`, `"karras"`, `"exponential"`, `"sgm_uniform"`, `"simple"`
  - `denoise` (float): `1.0` for Text-to-Image; `0.4 - 0.7` for Image-to-Image

### 2. `CheckpointLoaderSimple`
Loads weights and encoders.

- **Inputs**: `ckpt_name` (combo)
- **Outputs**:
  - Slot 0: `MODEL`
  - Slot 1: `CLIP`
  - Slot 2: `VAE`
- **Widget Values**: `["sd_xl_base_1.0.safetensors"]`

### 3. `CLIPTextEncode`
Converts positive or negative text strings into prompt conditioning.

- **Inputs**: `clip` (CLIP)
- **Outputs**: `CONDITIONING`
- **Widget Values**: `["your detailed prompt text here"]`

### 4. `EmptyLatentImage`
Generates initial noise canvas for Text-to-Image.

- **Outputs**: `LATENT`
- **Widget Values**: `[width, height, batch_size]`
- **Recommended SDXL Aspect Ratios**:
  - Square: `1024 x 1024`
  - Portrait: `896 x 1152` or `832 x 1216`
  - Landscape: `1152 x 896` or `1216 x 832`
  - Ultra-wide: `1344 x 768`

### 5. `LoadImage` & `VAEEncode`
Loads an existing image for Image-to-Image pipelines.

- `LoadImage`:
  - **Outputs**: Slot 0: `IMAGE`, Slot 1: `MASK`
  - **Widget Values**: `["image_filename.png", "image"]`
- `VAEEncode`:
  - **Inputs**: `pixels` (IMAGE), `vae` (VAE)
  - **Outputs**: `LATENT`

### 6. `VAEDecode` & `SaveImage`
Decodes latent representations back into pixels and writes files to disk.

- `VAEDecode`:
  - **Inputs**: `samples` (LATENT), `vae` (VAE)
  - **Outputs**: `IMAGE`
- `SaveImage`:
  - **Inputs**: `images` (IMAGE)
  - **Widget Values**: `["filename_prefix"]` (Output saved to `ComfyUI\output\<prefix>_00001_.png`)

---

## 3. Programmatic Workflow Inspection & Editing

Use Python with ComfyUI's embedded environment to safely inspect or modify existing workflows without breaking graph integrity.

### Inspecting Workflow Nodes and Settings

```python
import json

path = r"C:\W6\_Progs\ComfyUI_windows_portable\ComfyUI\user\default\workflows\my_workflow.json"
with open(path, "r", encoding="utf-8") as f:
    wf = json.load(f)

print(f"Total Nodes: {len(wf.get('nodes', []))}")
for node in wf.get("nodes", []):
    print(f"ID {node['id']:2d} | Type: {node['type']:<22} | Title: {node.get('title', '')}")
```

### Updating Prompts, Seeds, and Steps

```python
import json

path = r"C:\W6\_Progs\ComfyUI_windows_portable\ComfyUI\user\default\workflows\my_workflow.json"
with open(path, "r", encoding="utf-8") as f:
    wf = json.load(f)

for node in wf.get("nodes", []):
    # Update positive prompt
    if node["type"] == "CLIPTextEncode" and node.get("title") == "Positive Prompt":
        node["widgets_values"] = ["new positive prompt"]
        if "widgets_values_named" in node:
            node["widgets_values_named"]["text"] = "new positive prompt"
            
    # Update KSampler
    elif node["type"] == "KSampler":
        # [seed, control, steps, cfg, sampler, scheduler, denoise]
        node["widgets_values"][2] = 30     # steps
        node["widgets_values"][3] = 7.5    # cfg
        node["widgets_values"][4] = "dpmpp_2m"
        node["widgets_values"][5] = "karras"

with open(path, "w", encoding="utf-8") as f:
    json.dump(wf, f, indent=2)
```

---

## 4. Location Guidelines

When saving workflows:
1. **ComfyUI Template Library**:
   `C:\W6\_Progs\ComfyUI_windows_portable\ComfyUI\user\default\workflows\<workflow_name>.json`
   *(Appears in the ComfyUI Web UI sidebar/templates).*
2. **Project Workspace**:
   `<workspace_root>\<workflow_name>.json`
   *(Maintains version control and team visibility).*
