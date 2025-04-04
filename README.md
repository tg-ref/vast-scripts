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


# First, install the core ComfyUI
```bash
cd /workspace && curl -L -o setup_comfyui.sh https://raw.githubusercontent.com/DnsSrinath/vast-scripts/main/setup_comfyui.sh && chmod +x setup_comfyui.sh && ./setup_comfyui.sh
```

# Next, install WAN 2.1 and other extensions
```bash
cd /workspace && curl -L -o setup_extensions.sh https://raw.githubusercontent.com/DnsSrinath/vast-scripts/main/setup_extensions.sh && chmod +x setup_extensions.sh && ./setup_extensions.sh
```

# Finally, start ComfyUI
```bash
cd /workspace && curl -L -o start_comfyui.sh https://raw.githubusercontent.com/DnsSrinath/vast-scripts/main/start_comfyui.sh && chmod +x start_comfyui.sh && ./start_comfyui.sh
```




