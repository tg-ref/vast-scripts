#!/bin/bash
# Fixed ComfyUI Extensions Installation Script
# https://github.com/DnsSrinath/vast-scripts

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting ComfyUI extensions installation..."

# Verify ComfyUI is installed
if [ ! -d "/workspace/ComfyUI" ]; then
    log "ERROR: ComfyUI not found. Please install it first."
    exit 1
fi

# Make sure custom_nodes directory exists
mkdir -p /workspace/ComfyUI/custom_nodes
cd /workspace/ComfyUI/custom_nodes

# Function to install extension
install_extension() {
    local name="$1"
    local repo_url="$2"
    local target_dir="/workspace/ComfyUI/custom_nodes/$name"
    
    # Skip if already exists and has __init__.py
    if [ -d "$target_dir" ] && [ -f "$target_dir/__init__.py" ]; then
        log "$name already exists and has __init__.py, skipping."
        return 0
    elif [ -d "$target_dir" ]; then
        log "$name exists but may be incomplete. Removing and reinstalling."
        rm -rf "$target_dir"
    fi
    
    log "Installing $name..."
    
    # Clone directly - most reliable method
    if git clone --depth=1 "$repo_url" "$target_dir"; then
        log "Successfully installed $name"
        
        # Verify __init__.py exists
        if [ ! -f "$target_dir/__init__.py" ]; then
            log "WARNING: $name is missing __init__.py file"
        fi
        
        # Install requirements if present
        if [ -f "$target_dir/requirements.txt" ]; then
            log "Installing requirements for $name"
            cd "$target_dir"
            python3 -m pip install -r requirements.txt
            cd ..
        fi
        return 0
    else
        log "ERROR: Failed to install $name"
        return 1
    fi
}

# Install core extensions
log "Installing core extensions..."

# ComfyUI-Manager
install_extension "ComfyUI-Manager" "https://github.com/ltdrdata/ComfyUI-Manager.git"

# ComfyUI-Impact-Pack
install_extension "ComfyUI-Impact-Pack" "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git"

# ComfyUI-WAN-Suite
install_extension "ComfyUI-WAN-Suite" "https://github.com/WASasquatch/ComfyUI-WAN-Suite.git"

# Additional extensions
log "Installing additional extensions..."

# ComfyUI-nodes-base
install_extension "comfyui-nodes-base" "https://github.com/Acly/comfyui-nodes-base.git"

# ComfyUI_IPAdapter_plus
install_extension "ComfyUI_IPAdapter_plus" "https://github.com/cubiq/ComfyUI_IPAdapter_plus.git"

# comfyui-nodes-rgthree
install_extension "comfyui-nodes-rgthree" "https://github.com/rgthree/comfyui-nodes-rgthree.git"

# Install common dependencies
log "Installing common Python dependencies for extensions..."
python3 -m pip install opencv-python onnxruntime onnx transformers accelerate safetensors
python3 -m pip install insightface timm fairscale prettytable
python3 -m pip install ultralytics

# Verify installation
log "Extension installation complete!"
log "Installed extensions:"
for dir in */; do
    if [ -d "$dir" ] && [ -f "${dir}__init__.py" ]; then
        log "  - ${dir%/} (complete)"
    elif [ -d "$dir" ]; then
        log "  - ${dir%/} (may be incomplete)"
    fi
done

# Create credentials file to avoid GitHub authentication prompts
git config --global credential.helper store

# Final instructions
log "ComfyUI extensions setup complete!"
log "To start ComfyUI: cd /workspace && ./start_comfyui.sh"
log "Access ComfyUI at: http://$(hostname -I | awk '{print $1}'):8188"
