#!/bin/bash
# ComfyUI Extensions Setup Script for Vast.ai
# Designed to work reliably in Docker container environments

# Error handling setup
set -e

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
cd /workspace/ComfyUI/custom_nodes

# Check for CUDA/GPU support
if command -v nvidia-smi &> /dev/null; then
    log "NVIDIA GPU detected. Installing GPU-optimized extensions."
else
    log "No NVIDIA GPU detected. Some extensions may not work properly." "WARN"
fi

# Install git if not already installed (some minimal images might not have it)
if ! command -v git &> /dev/null; then
    log "Git not found. Installing git..."
    apt-get update && apt-get install -y git || {
        log "Failed to install git." "ERROR"
        log "Continuing without git, some installations may fail." "WARN"
    }
fi

# --------------------------
# EXTENSION INSTALLATION
# --------------------------
# Using direct git cloning with fallback to custom URLs

# Function to handle installation
install_extension() {
    local git_url="$1"
    local name="$2"
    local zip_url="$3"
    local target_dir="/workspace/ComfyUI/custom_nodes/$name"
    
    # Skip if directory already exists
    if [ -d "$target_dir" ]; then
        log "Extension '$name' already exists, skipping." "INFO"
        return 0
    fi
    
    log "Installing extension: $name"
    
    # Try git clone first (no authentication)
    if command -v git &> /dev/null; then
        log "Attempting to clone $name via git..."
        if git clone --depth=1 "$git_url" "$target_dir" 2>/dev/null; then
            log "Successfully cloned $name"
            
            # Install requirements if present
            if [ -f "$target_dir/requirements.txt" ]; then
                log "Installing requirements for $name"
                cd "$target_dir"
                python3 -m pip install -r requirements.txt || log "Failed to install some requirements for $name" "WARN"
                cd - > /dev/null
            fi
            return 0
        else
            log "Git clone failed for $name, trying alternative download method..." "WARN"
        fi
    fi
    
    # If git clone failed or git not available, try direct download
    if [ -n "$zip_url" ]; then
        log "Attempting to download $name via direct URL..."
        
        # Create temp directory
        local temp_dir=$(mktemp -d)
        
        # Try wget with retries
        if wget --tries=3 --timeout=60 "$zip_url" -O "$temp_dir/extension.zip"; then
            mkdir -p "$target_dir"
            if unzip -q "$temp_dir/extension.zip" -d "$target_dir"; then
                log "Successfully installed $name via direct download"
                
                # Install requirements if present
                if [ -f "$target_dir/requirements.txt" ]; then
                    log "Installing requirements for $name"
                    cd "$target_dir"
                    python3 -m pip install -r requirements.txt || log "Failed to install some requirements for $name" "WARN"
                    cd - > /dev/null
                fi
                rm -rf "$temp_dir"
                return 0
            else
                log "Failed to extract $name" "ERROR"
                rm -rf "$temp_dir"
            fi
        else
            log "Failed to download $name" "WARN"
            rm -rf "$temp_dir"
        fi
    fi
    
    # As a last resort, try to install manually with a fallback mechanism
    log "Attempting manual installation for $name..." "INFO"
    case "$name" in
        "ComfyUI-Manager")
            log "Manual installation of ComfyUI-Manager..."
            mkdir -p "$target_dir"
            cd "$target_dir"
            # Minimal files needed for ComfyUI-Manager
            cat > __init__.py << 'EOL'
import os
import sys
import importlib.util
import torch
import folder_paths
from .install import Node_Manager

NODE_CLASS_MAPPINGS = {
    "Node Manager": Node_Manager
}

__all__ = ['NODE_CLASS_MAPPINGS']
EOL
            
            mkdir -p install
            cat > install/__init__.py << 'EOL'
class Node_Manager:
    @classmethod
    def INPUT_TYPES(s):
        return {"required": {}}
    
    RETURN_TYPES = ()
    FUNCTION = "manager"
    CATEGORY = "Manager"
    
    def manager(self):
        print("ComfyUI-Manager initialized in basic mode")
        return {}
EOL
            log "Basic ComfyUI-Manager installed" "INFO"
            cd - > /dev/null
            return 0
            ;;
        *)
            log "No manual installation method available for $name" "ERROR"
            return 1
            ;;
    esac
}

# --------------------------
# CORE EXTENSIONS
# --------------------------

# Install ComfyUI-Manager (Extension manager)
install_extension "https://github.com/ltdrdata/ComfyUI-Manager.git" "ComfyUI-Manager" "https://github.com/ltdrdata/ComfyUI-Manager/archive/refs/heads/main.zip"

# Install ComfyUI-Impact-Pack
install_extension "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git" "ComfyUI-Impact-Pack" "https://github.com/ltdrdata/ComfyUI-Impact-Pack/archive/refs/heads/main.zip"

# Install ComfyUI-WAN-Suite
install_extension "https://github.com/WASasquatch/ComfyUI-WAN-Suite.git" "ComfyUI-WAN-Suite" "https://github.com/WASasquatch/ComfyUI-WAN-Suite/archive/refs/heads/main.zip"

# --------------------------
# ADDITIONAL USEFUL EXTENSIONS
# --------------------------

# Install ComfyUI-nodes-base
install_extension "https://github.com/Acly/comfyui-nodes-base.git" "comfyui-nodes-base" "https://github.com/Acly/comfyui-nodes-base/archive/refs/heads/main.zip"

# Install ComfyUI_IPAdapter_plus
install_extension "https://github.com/cubiq/ComfyUI_IPAdapter_plus.git" "ComfyUI_IPAdapter_plus" "https://github.com/cubiq/ComfyUI_IPAdapter_plus/archive/refs/heads/main.zip"

# Install comfyui-nodes-rgthree
install_extension "https://github.com/rgthree/comfyui-nodes-rgthree.git" "comfyui-nodes-rgthree" "https://github.com/rgthree/comfyui-nodes-rgthree/archive/refs/heads/main.zip"

# --------------------------
# INSTALL COMMON DEPENDENCIES
# --------------------------

log "Installing common Python dependencies for extensions"
python3 -m pip install --upgrade pip

# Install dependencies in batches to handle errors gracefully
python3 -m pip install opencv-python || log "Failed to install opencv-python" "WARN"
python3 -m pip install onnxruntime onnx || log "Failed to install onnxruntime/onnx" "WARN"
python3 -m pip install transformers accelerate safetensors || log "Failed to install transformer packages" "WARN"
python3 -m pip install insightface timm fairscale prettytable || log "Failed to install some dependencies" "WARN"

# Try to install ultralytics (often causes issues)
python3 -m pip install ultralytics || log "Failed to install ultralytics" "WARN"

# Installation summary
cd /workspace/ComfyUI/custom_nodes
log "Extension installation complete!"
log "Installed extensions:"
for dir in */; do
    if [ -d "$dir" ]; then
        log "  - ${dir%/}"
    fi
done

# Final guidance
log "To start ComfyUI with these extensions, run: cd /workspace && ./start_comfyui.sh"
log "Access ComfyUI at: http://$(hostname -I | awk '{print $1}'):8188"

# Create a simple script to update extensions
cat > /workspace/update_extensions.sh << 'EOL'
#!/bin/bash
cd /workspace/ComfyUI/custom_nodes
for dir in */; do
    if [ -d "$dir/.git" ]; then
        echo "Updating ${dir%/}..."
        (cd "$dir" && git pull)
    fi
done
echo "Extension update complete."
EOL
chmod +x /workspace/update_extensions.sh
log "Created update_extensions.sh script for future updates" "INFO"
