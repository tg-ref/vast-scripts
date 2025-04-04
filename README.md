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

## Customization
- Modify scripts to add more extensions
- Adjust model download locations
- Configure additional startup parameters

## Requirements
- Vast.ai instance with CUDA support
- Python 3.8+
- Compatible GPU (NVIDIA recommended)

## Contributing
Open issues or pull requests to improve the scripts.
