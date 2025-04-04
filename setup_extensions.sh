#!/bin/bash
# ComfyUI Extensions Installation Script with verified direct download links
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

# Function to download and install extension
install_extension() {
    local name="$1"
    local zip_url="$2"
    local target_dir="/workspace/ComfyUI/custom_nodes/$name"
    
    if [ -d "$target_dir" ]; then
        log "$name already exists, skipping."
        return 0
    fi
    
    log "Installing $name..."
    wget -O extension.zip "$zip_url"
    
    if [ -f "extension.zip" ]; then
        mkdir -p "$target_dir"
        mkdir -p temp_extract
        unzip -q extension.zip -d temp_extract
        
        # Find the correct directory and move its contents
        if [ -d "temp_extract/$name-main" ]; then
            mv "temp_extract/$name-main"/* "$target_dir"/
        elif [ -d "temp_extract/$name-master" ]; then
            mv "temp_extract/$name-master"/* "$target_dir"/
        else
            # Try to find any directory and move its contents
            first_dir=$(find temp_extract -maxdepth 1 -type d | sort | head -n 2 | tail -n 1)
            if [ -n "$first_dir" ]; then
                mv "$first_dir"/* "$target_dir"/
            else
                # If all else fails, move everything
                mv temp_extract/* "$target_dir"/
            fi
        fi
        
        # Clean up
        rm -rf temp_extract extension.zip
        
        # Install requirements
        if [ -f "$target_dir/requirements.txt" ]; then
            log "Installing requirements for $name..."
            cd "$target_dir"
            python3 -m pip install -r requirements.txt || log "WARNING: Some requirements for $name failed to install"
            cd /workspace/ComfyUI/custom_nodes
        fi
        
        log "$name installed successfully."
        return 0
    else
        log "Failed to download $name."
        return 1
    fi
}

# Install core extensions
log "Installing core extensions..."

# ComfyUI-Manager
install_extension "ComfyUI-Manager" "https://github.com/ltdrdata/ComfyUI-Manager/archive/refs/heads/main.zip"

# ComfyUI-Impact-Pack
install_extension "ComfyUI-Impact-Pack" "https://github.com/ltdrdata/ComfyUI-Impact-Pack/archive/refs/tags/v2.5.6.zip"

# ComfyUI-WAN-Suite
install_extension "ComfyUI-WAN-Suite" "https://github.com/WASasquatch/ComfyUI-WAN-Suite/archive/refs/heads/main.zip"

# Install additional extensions
log "Installing additional extensions..."

# ComfyUI-nodes-base
install_extension "comfyui-nodes-base" "https://github.com/Acly/comfyui-nodes-base/archive/refs/heads/main.zip"

# ComfyUI_IPAdapter_plus
install_extension "ComfyUI_IPAdapter_plus" "https://github.com/cubiq/ComfyUI_IPAdapter_plus/archive/refs/heads/main.zip"

# comfyui-nodes-rgthree
install_extension "comfyui-nodes-rgthree" "https://github.com/rgthree/comfyui-nodes-rgthree/archive/refs/heads/main.zip"

# Install common dependencies
log "Installing common Python dependencies for extensions..."
python3 -m pip install opencv-python onnxruntime onnx transformers accelerate safetensors || log "WARNING: Some core dependencies failed to install"
python3 -m pip install insightface timm fairscale prettytable || log "WARNING: Some additional dependencies failed to install"
python3 -m pip install ultralytics || log "WARNING: Failed to install ultralytics"

# Verify installation
log "Extension installation complete!"
log "Installed extensions:"
for dir in */; do
    if [ -d "$dir" ]; then
        log "  - ${dir%/}"
    fi
done

# Final instructions
log "ComfyUI extensions setup complete!"
log "To start ComfyUI: cd /workspace && ./start_comfyui.sh"
log "Access ComfyUI at: http://$(hostname -I | awk '{print $1}'):8188"
