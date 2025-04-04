# Vast.ai ComfyUI Setup Scripts

## Overview
These scripts automate the setup and deployment of ComfyUI on Vast.ai instances with advanced configuration and extension support.

## Scripts

### 1. `universal_comfyui_setup.sh`
- **Universal, One-Command Setup Solution**
- Automatically downloads and runs all necessary setup scripts
- Configures ComfyUI, extensions, and persistent service
- Performs comprehensive system diagnostic
- Ideal for quick and consistent deployment across different instances

### 2. `setup_comfyui.sh`
- Prepares the core ComfyUI environment
- Installs necessary dependencies
- Configures GPU and CPU environments
- Creates model directories

### 3. `setup_extensions.sh`
- Installs ComfyUI extensions
- Adds WAN 2.1 Suite
- Downloads and configures additional models
- Supports easy extension management

### 4. `start_comfyui.sh`
- Configures network settings
- Sets up portal and Caddy configuration
- Manages ComfyUI process
- Provides logging and error handling

## Usage in Vast.ai

### Universal Setup (Recommended)
```bash
cd /workspace && curl -L -o universal_comfyui_setup.sh https://raw.githubusercontent.com/DnsSrinath/vast-scripts/main/universal_comfyui_setup.sh && chmod +x universal_comfyui_setup.sh && ./universal_comfyui_setup.sh
```

### Detailed Setup Sequence
```bash
# 1. Setup Core ComfyUI
cd /workspace && curl -L -o setup_comfyui.sh https://raw.githubusercontent.com/DnsSrinath/vast-scripts/main/setup_comfyui.sh && chmod +x setup_comfyui.sh && ./setup_comfyui.sh

# 2. Install Extensions
cd /workspace && curl -L -o setup_extensions.sh https://raw.githubusercontent.com/DnsSrinath/vast-scripts/main/setup_extensions.sh && chmod +x setup_extensions.sh && ./setup_extensions.sh

# 3. Start ComfyUI
cd /workspace && curl -L -o start_comfyui.sh https://raw.githubusercontent.com/DnsSrinath/vast-scripts/main/start_comfyui.sh && chmod +x start_comfyui.sh && ./start_comfyui.sh
```

## Installed Extensions

The setup includes the following popular extensions:

### Core Extensions
- **ComfyUI-Manager** - Extension manager for installing additional nodes
- **ComfyUI-Impact-Pack** - Collection of useful nodes for image processing and workflows
- **ComfyUI-WAN-Suite 2.1** - Comprehensive suite of utility nodes
- **ComfyUI-Nodes-Base** - Base set of additional nodes

### Additional Extensions
- **ComfyUI_IPAdapter_Plus** - Enhanced IP-Adapter integration
- **comfyui-nodes-rgthree** - Quality of life improvements and workflow organization
- **ComfyUI-Creative-Interpolation** - Animation and interpolation tools
- **comfyui_controlnet_aux** - Additional ControlNet preprocessing nodes

## Dependencies

The setup installs these important dependencies:
- PyTorch with CUDA support
- xformers for efficient attention mechanisms
- opencv-python for image processing
- ultralytics for YOLO object detection
- insightface for face detection and analysis
- onnxruntime and onnx for neural network execution
- transformers for text processing
- Other supporting libraries for AI functionality

## Access and Logs
- ComfyUI Interface: `http://<instance-ip>:8188`
- Universal Setup Logs: `/workspace/comfyui_diagnostic.log`
- ComfyUI Logs: `/workspace/comfyui.log`
- Check logs: `tail -f /workspace/comfyui_diagnostic.log`

## Troubleshooting
- Verify GPU availability with `nvidia-smi`
- Check Python environment with `which python`
- Inspect diagnostic logs for specific errors
- Use the universal setup script for consistent deployment
- If extension installation fails, try running ComfyUI first and install extensions through the UI

## Docker Container Notes
- These scripts are designed to run in Docker containers on Vast.ai
- Systemd is not available in these containers, so persistence is handled through alternative methods
- Extensions are installed via direct download to avoid GitHub authentication issues

## Customization
- Modify scripts to add more extensions
- Adjust model download locations
- Configure additional startup parameters

## Requirements
- Vast.ai instance with CUDA support
- Python 3.8+
- Compatible GPU (NVIDIA recommended)

## Contributing
Open issues or pull requests to improve the scripts at [GitHub Repository](https://github.com/DnsSrinath/vast-scripts).
