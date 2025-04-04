#!/bin/bash
# ComfyUI Extensions Setup Script for Vast.ai
# Designed to work reliably in Docker container environments

# Error handling setup
set -e
trap 'echo "Error on line $LINENO. Command: $BASH_COMMAND"' ERR

# Logging function
log() {
    local level="${2:-INFO}"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[${timestamp}] [${level}] $1"
    echo "[${timestamp}] [${level}] $1" >> "/workspace/comfyui_extensions.log"
}

log "Starting ComfyUI Extensions Setup"

# Verify ComfyUI is installed
if [ ! -d "/workspace/ComfyUI" ]; then
    log "ComfyUI not found at /workspace/ComfyUI. Please install it first." "ERROR"
    exit 1
fi

# Make sure custom_nodes directory exists
mkdir -p /workspace/ComfyUI/custom_nodes

# Check for CUDA/GPU support
if command -v nvidia-smi &> /dev/null; then
    log "NVIDIA GPU detected. Installing GPU-optimized extensions."
else
    log "No NVIDIA GPU detected. Some extensions may not work properly." "WARN"
fi

# --------------------------
# EXTENSION INSTALLATION
# --------------------------
# All installations use direct downloads to avoid GitHub authentication issues

# Function to download and install an extension
install_extension() {
    local url="$1"
    local name="$2"
    local target_dir="/workspace/ComfyUI/custom_nodes/$name"
    
    # Skip if directory already exists
    if [ -d "$target_dir" ]; then
        log "Extension '$name' already exists, skipping." "INFO"
        return 0
    fi
    
    log "Installing extension: $name"
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    
    # Download extension
    if wget --tries=3 --timeout=60 -q "$url" -O "$temp_dir/extension.zip"; then
        # Extract the extension
        mkdir -p "$target_dir"
        if unzip -q "$temp_dir/extension.zip" -d "$target_dir"; then
            log "Successfully installed $name"
            
            # Install requirements if present
            if [ -f "$target_dir/requirements.txt" ]; then
                log "Installing requirements for $name"
                python3 -m pip install -r "$target_dir/requirements.txt" || log "Failed to install some requirements for $name" "WARN"
            fi
        else
            log "Failed to extract $name" "ERROR"
            return 1
        fi
    else
        log "Failed to download $name" "ERROR"
        return 1
    fi
    
    # Clean up
    rm -rf "$temp_dir"
    return 0
}

# --------------------------
# CORE EXTENSIONS
# --------------------------

# ComfyUI Manager (Extension manager)
log "Installing ComfyUI Manager"
install_extension "https://huggingface.co/datasets/comfyanonymous/ComfyUI_extensions/resolve/main/ltdrdata-ComfyUI-Manager.zip" "ComfyUI-Manager"

# ComfyUI Impact Pack (Essential nodes collection)
log "Installing ComfyUI Impact Pack"
install_extension "https://huggingface.co/datasets/comfyanonymous/ComfyUI_extensions/resolve/main/ltdrdata-ComfyUI-Impact-Pack.zip" "ComfyUI-Impact-Pack"

# ComfyUI WAN Suite 2.1 (Comprehensive node collection)
log "Installing ComfyUI WAN Suite 2.1"
install_extension "https://huggingface.co/datasets/comfyanonymous/ComfyUI_extensions/resolve/main/WASasquatch-ComfyUI-WAN-Suite.zip" "ComfyUI-WAN-Suite"

# --------------------------
# ADDITIONAL USEFUL EXTENSIONS
# --------------------------

# ComfyUI Nodes Base
log "Installing ComfyUI Nodes Base"
install_extension "https://huggingface.co/datasets/comfyanonymous/ComfyUI_extensions/resolve/main/Acly-comfyui-nodes-base.zip" "comfyui-nodes-base"

# IPAdapter Plus
log "Installing IPAdapter Plus"
install_extension "https://huggingface.co/datasets/comfyanonymous/ComfyUI_extensions/resolve/main/cubiq-ComfyUI_IPAdapter_plus.zip" "ComfyUI_IPAdapter_plus"

# rgthree's workflow organization nodes
log "Installing rgthree nodes"
install_extension "https://huggingface.co/datasets/comfyanonymous/ComfyUI_extensions/resolve/main/rgthree-comfyui-nodes-rgthree.zip" "comfyui-nodes-rgthree"

# Creative Interpolation (for animations)
log "Installing Creative Interpolation"
install_extension "https://huggingface.co/datasets/comfyanonymous/ComfyUI_extensions/resolve/main/ComfyUI-Creative-Interpolation.zip" "ComfyUI-Creative-Interpolation"

# ControlNet Auxiliary Preprocessors
log "Installing ControlNet Auxiliary Preprocessors"
install_extension "https://huggingface.co/datasets/comfyanonymous/ComfyUI_extensions/resolve/main/comfyui_controlnet_aux.zip" "comfyui_controlnet_aux"

# --------------------------
# INSTALL COMMON DEPENDENCIES
# --------------------------

log "Installing common Python dependencies for extensions"
python3 -m pip install --upgrade pip
python3 -m pip install opencv-python ultralytics insightface onnxruntime onnx timm fairscale prettytable transformers accelerate safetensors || log "Some dependencies failed to install" "WARN"

# Installation summary
log "Extension installation complete!"
log "Installed extensions:"
ls -la /workspace/ComfyUI/custom_nodes/

# Final guidance
log "To start ComfyUI with these extensions, run: cd /workspace && ./start_comfyui.sh"
log "Access ComfyUI at: http://$(hostname -I | awk '{print $1}'):8188"
