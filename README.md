# Vast.ai ComfyUI Setup Scripts

## 🧠 Overview
This repository automates the complete setup of **ComfyUI** on **Vast.ai** instances, including extensions like **WAN 2.1**, **ControlNet**, and **video-to-video** support. It is designed to make deployment fast, consistent, and robust across instances.

---

## 📜 Scripts

### 1. `universal_comfyui_setup.sh`
- Universal one-command installer
- Automatically downloads all other setup scripts
- Installs core dependencies, extensions, and models
- Configures persistent auto-start service
- Runs system diagnostics and logs setup output

### 2. `setup_comfyui.sh`
- Installs ComfyUI
- Creates directory structure (`models/`, `custom_nodes/`)
- Installs Python and base requirements

### 3. `setup_extensions.sh`
- Adds essential ComfyUI custom nodes
- Installs:
  - WAN Node Suite 2.1
  - Impact Pack
  - ControlNet preprocessors
  - Interpolation, IP Adapter, rgthree, and more

### 4. `start_comfyui.sh`
- Launches ComfyUI on port `8188`
- Supports CORS headers
- Backgrounds the server with logging

### 5. `download_models.sh`
- Downloads:
  - Stable Diffusion v1.5 model
  - ControlNet `.pth` models (Depth, Canny)
- Ensures correct folder structure for `models/checkpoints` and `models/controlnet`

---

## 🚀 How to Use on Vast.ai

### ✅ Universal Setup (Recommended)
Run this from inside your Vast.ai container:

```bash
cd /workspace && curl -L -o universal_comfyui_setup.sh https://raw.githubusercontent.com/DnsSrinath/vast-scripts/main/universal_comfyui_setup.sh && chmod +x universal_comfyui_setup.sh && ./universal_comfyui_setup.sh
