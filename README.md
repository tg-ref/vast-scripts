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
cd /workspace
# Edit the script to ensure it uses the correct URLs for git clone operations
sed -i 's/git clone /git clone --depth 1 https:\/\//g' setup_comfyui.sh
# Explicitly fix the ComfyUI repo URL
sed -i 's/git clone --depth 1 https:\/\/https:\/\/github.com/git clone --depth 1 https:\/\/github.com/g' setup_comfyui.sh
# Run the modified script
./setup_comfyui.sh

# in New instance
```bash
cd /workspace && curl -L -o setup.sh https://raw.githubusercontent.com/DnsSrinath/vast-scripts/main/setup_comfyui.sh && chmod +x setup.sh && ./setup.sh

