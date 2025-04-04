# vast-scripts

# Vast.ai Scripts for ComfyUI

This repository contains scripts for setting up ComfyUI and various extensions on Vast.ai instances.

## Setup ComfyUI with WAN 2.1

The `setup_comfyui.sh` script will:

1. Install ComfyUI if not already installed
2. Configure it to be accessible via the Vast.ai portal
3. Install the WAN 2.1 Suite extension
4. Download the WAN 2.1 model

### Usage

In your Vast.ai instance creation, use the following onstart command:

```bash
cd /workspace && curl -o setup_comfyui.sh https://raw.githubusercontent.com/DnsSrinath/vast-scripts/main/setup_comfyui.sh && chmod +x setup_comfyui.sh && ./setup_comfyui.sh > /workspace/setup.log 2>&1
