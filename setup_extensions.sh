#!/bin/bash
# ComfyUI Extensions Setup for Vast.ai - No GitHub Authentication Required
# https://github.com/DnsSrinath/vast-scripts

# Logging function
log() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[${timestamp}] $1"
}

log "Starting ComfyUI Extensions Setup (No GitHub Auth)"

# Verify ComfyUI is installed
if [ ! -d "/workspace/ComfyUI" ]; then
    log "ERROR: ComfyUI not found. Please install it first."
    exit 1
fi

# Make sure custom_nodes directory exists
mkdir -p /workspace/ComfyUI/custom_nodes
cd /workspace/ComfyUI/custom_nodes

# Check for CUDA/GPU support
if command -v nvidia-smi &> /dev/null; then
    log "NVIDIA GPU detected. Installing GPU-optimized extensions."
else
    log "WARNING: No NVIDIA GPU detected. Some extensions may not work properly."
fi

# Install common dependencies first
log "Installing essential dependencies..."
python3 -m pip install --upgrade pip
python3 -m pip install opencv-python onnxruntime onnx transformers accelerate safetensors || log "WARNING: Some core dependencies failed to install"

# Function to download and install an extension from direct download URL
install_from_direct_url() {
    local url="$1"
    local name="$2"
    local target_dir="/workspace/ComfyUI/custom_nodes/$name"
    
    if [ -d "$target_dir" ]; then
        log "$name already exists, skipping."
        return 0
    fi
    
    log "Installing $name via direct download..."
    
    # Create temp directory
    local temp_dir=$(mktemp -d)
    
    if curl -L "$url" -o "$temp_dir/extension.zip"; then
        mkdir -p "$target_dir"
        unzip -q "$temp_dir/extension.zip" -d "$temp_dir/extracted"
        
        # Find the actual directory inside the zip (usually has -main or -master suffix)
        local extracted_dir=$(find "$temp_dir/extracted" -mindepth 1 -maxdepth 1 -type d | head -n 1)
        
        if [ -n "$extracted_dir" ]; then
            # Move contents to target directory
            mv "$extracted_dir"/* "$target_dir"/
            log "Successfully installed $name"
            
            # Install requirements if present
            if [ -f "$target_dir/requirements.txt" ]; then
                log "Installing requirements for $name"
                cd "$target_dir"
                python3 -m pip install -r requirements.txt || log "WARNING: Some requirements for $name failed to install"
                cd ..
            fi
            
            # Clean up
            rm -rf "$temp_dir"
            return 0
        else
            log "ERROR: Could not find extracted directory for $name"
            rm -rf "$temp_dir"
            return 1
        fi
    else
        log "ERROR: Failed to download $name"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Direct download links from Hugging Face and other sources that don't require authentication
log "Installing extensions from direct download sources..."

# ComfyUI Manager
log "Installing ComfyUI-Manager..."
if [ ! -d "ComfyUI-Manager" ]; then
    install_from_direct_url "https://huggingface.co/datasets/comfyanonymous/ComfyUI_extensions/resolve/main/ltdrdata-ComfyUI-Manager.zip" "ComfyUI-Manager" || \
    install_from_direct_url "https://codeberg.org/comfyanonymous/ComfyUI_extensions/raw/branch/main/ltdrdata-ComfyUI-Manager.zip" "ComfyUI-Manager" || \
    log "WARNING: Failed to install ComfyUI-Manager"
else
    log "ComfyUI-Manager already exists, skipping."
fi

# ComfyUI Impact Pack
log "Installing ComfyUI-Impact-Pack..."
if [ ! -d "ComfyUI-Impact-Pack" ]; then
    install_from_direct_url "https://huggingface.co/datasets/comfyanonymous/ComfyUI_extensions/resolve/main/ltdrdata-ComfyUI-Impact-Pack.zip" "ComfyUI-Impact-Pack" || \
    install_from_direct_url "https://codeberg.org/comfyanonymous/ComfyUI_extensions/raw/branch/main/ltdrdata-ComfyUI-Impact-Pack.zip" "ComfyUI-Impact-Pack" || \
    log "WARNING: Failed to install ComfyUI-Impact-Pack"
else
    log "ComfyUI-Impact-Pack already exists, skipping."
fi

# WAN Suite
log "Installing ComfyUI-WAN-Suite..."
if [ ! -d "ComfyUI-WAN-Suite" ]; then
    install_from_direct_url "https://huggingface.co/datasets/comfyanonymous/ComfyUI_extensions/resolve/main/WASasquatch-ComfyUI-WAN-Suite.zip" "ComfyUI-WAN-Suite" || \
    install_from_direct_url "https://codeberg.org/comfyanonymous/ComfyUI_extensions/raw/branch/main/WASasquatch-ComfyUI-WAN-Suite.zip" "ComfyUI-WAN-Suite" || \
    log "WARNING: Failed to install ComfyUI-WAN-Suite"
else
    log "ComfyUI-WAN-Suite already exists, skipping."
fi

# IPAdapter Plus
log "Installing ComfyUI_IPAdapter_plus..."
if [ ! -d "ComfyUI_IPAdapter_plus" ]; then
    install_from_direct_url "https://huggingface.co/datasets/comfyanonymous/ComfyUI_extensions/resolve/main/cubiq-ComfyUI_IPAdapter_plus.zip" "ComfyUI_IPAdapter_plus" || \
    install_from_direct_url "https://codeberg.org/comfyanonymous/ComfyUI_extensions/raw/branch/main/cubiq-ComfyUI_IPAdapter_plus.zip" "ComfyUI_IPAdapter_plus" || \
    log "WARNING: Failed to install ComfyUI_IPAdapter_plus"
else
    log "ComfyUI_IPAdapter_plus already exists, skipping."
fi

# ComfyUI Nodes Base
log "Installing comfyui-nodes-base..."
if [ ! -d "comfyui-nodes-base" ]; then
    install_from_direct_url "https://huggingface.co/datasets/comfyanonymous/ComfyUI_extensions/resolve/main/Acly-comfyui-nodes-base.zip" "comfyui-nodes-base" || \
    install_from_direct_url "https://codeberg.org/comfyanonymous/ComfyUI_extensions/raw/branch/main/Acly-comfyui-nodes-base.zip" "comfyui-nodes-base" || \
    log "WARNING: Failed to install comfyui-nodes-base"
else
    log "comfyui-nodes-base already exists, skipping."
fi

# rgthree nodes
log "Installing comfyui-nodes-rgthree..."
if [ ! -d "comfyui-nodes-rgthree" ]; then
    install_from_direct_url "https://huggingface.co/datasets/comfyanonymous/ComfyUI_extensions/resolve/main/rgthree-comfyui-nodes-rgthree.zip" "comfyui-nodes-rgthree" || \
    install_from_direct_url "https://codeberg.org/comfyanonymous/ComfyUI_extensions/raw/branch/main/rgthree-comfyui-nodes-rgthree.zip" "comfyui-nodes-rgthree" || \
    log "WARNING: Failed to install comfyui-nodes-rgthree"
else
    log "comfyui-nodes-rgthree already exists, skipping."
fi

# Install additional dependencies that might be needed by the extensions
log "Installing additional dependencies..."
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
