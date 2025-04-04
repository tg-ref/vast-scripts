#!/bin/bash
# Robust ComfyUI Extensions Setup for Vast.ai
# Designed for reliable deployment across multiple instances
# https://github.com/DnsSrinath/vast-scripts

# Error handling
set -e

# Logging function
log() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[${timestamp}] $1"
}

log "Starting ComfyUI Extensions Setup"

# Verify ComfyUI is installed
if [ ! -d "/workspace/ComfyUI" ]; then
    log "ERROR: ComfyUI not found at /workspace/ComfyUI. Please install it first."
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

# Function to install an extension via git
install_extension() {
    local repo_url="$1"
    local dir_name="$2"
    local branch="${3:-main}"
    
    if [ -d "$dir_name" ]; then
        log "$dir_name already exists, skipping installation."
        return 0
    fi
    
    log "Installing $dir_name..."
    
    # Clone with depth=1 for faster downloads
    if git clone --depth=1 --branch "$branch" "$repo_url" "$dir_name"; then
        log "Successfully cloned $dir_name"
        
        # Install requirements if present
        if [ -f "$dir_name/requirements.txt" ]; then
            log "Installing requirements for $dir_name"
            cd "$dir_name"
            python3 -m pip install -r requirements.txt || log "WARNING: Some requirements for $dir_name failed to install"
            cd ..
        fi
        return 0
    else
        log "ERROR: Failed to clone $dir_name"
        return 1
    fi
}

# Install core extensions - retry mechanism built in
install_with_retry() {
    local repo_url="$1"
    local dir_name="$2"
    local branch="${3:-main}"
    local max_retries=3
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        if install_extension "$repo_url" "$dir_name" "$branch"; then
            return 0
        else
            retry_count=$((retry_count + 1))
            log "Retry $retry_count/$max_retries for $dir_name"
            sleep 2
        fi
    done
    
    log "ERROR: Failed to install $dir_name after $max_retries attempts"
    return 1
}

# Install essential dependencies first
log "Installing essential dependencies..."
python3 -m pip install --upgrade pip

# Core Extensions - Each with retry mechanism
log "Installing core extensions..."

# Install ComfyUI Manager
install_with_retry "https://github.com/ltdrdata/ComfyUI-Manager.git" "ComfyUI-Manager" || 
    log "WARNING: Failed to install ComfyUI-Manager"

# Install ComfyUI Impact Pack
install_with_retry "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git" "ComfyUI-Impact-Pack" || 
    log "WARNING: Failed to install ComfyUI-Impact-Pack"

# Install WAN Suite
install_with_retry "https://github.com/WASasquatch/ComfyUI-WAN-Suite.git" "ComfyUI-WAN-Suite" || 
    log "WARNING: Failed to install ComfyUI-WAN-Suite"

# Install additional useful extensions
log "Installing additional extensions..."

# Install node-base
install_with_retry "https://github.com/Acly/comfyui-nodes-base.git" "comfyui-nodes-base" || 
    log "WARNING: Failed to install comfyui-nodes-base"

# Install IPAdapter Plus
install_with_retry "https://github.com/cubiq/ComfyUI_IPAdapter_plus.git" "ComfyUI_IPAdapter_plus" || 
    log "WARNING: Failed to install ComfyUI_IPAdapter_plus"

# Install rgthree nodes
install_with_retry "https://github.com/rgthree/comfyui-nodes-rgthree.git" "comfyui-nodes-rgthree" || 
    log "WARNING: Failed to install comfyui-nodes-rgthree"

# Install ControlNet Aux
install_with_retry "https://github.com/Fannovel16/comfyui_controlnet_aux.git" "comfyui_controlnet_aux" || 
    log "WARNING: Failed to install comfyui_controlnet_aux"

# Install dependencies in batches with error handling
log "Installing common Python dependencies for extensions..."
python3 -m pip install opencv-python || log "WARNING: Failed to install opencv-python"
python3 -m pip install onnxruntime onnx || log "WARNING: Failed to install onnx packages"
python3 -m pip install transformers accelerate safetensors || log "WARNING: Failed to install transformer packages"
python3 -m pip install insightface timm fairscale prettytable || log "WARNING: Failed to install additional packages"
python3 -m pip install ultralytics || log "WARNING: Failed to install ultralytics"

# Verify installation
log "Extension installation complete!"
log "Installed extensions:"
for dir in */; do
    if [ -d "$dir" ]; then
        log "  - ${dir%/}"
    fi
done

# Create update helper script
cat > /workspace/update_extensions.sh << 'EOL'
#!/bin/bash
cd /workspace/ComfyUI/custom_nodes
for dir in */; do
    if [ -d "$dir/.git" ]; then
        echo "Updating ${dir%/}..."
        (cd "$dir" && git pull)
    fi
done
echo "Extension update complete!"
EOL
chmod +x /workspace/update_extensions.sh

# Final instructions
log "ComfyUI extensions setup complete!"
log "To start ComfyUI: cd /workspace && ./start_comfyui.sh"
log "To update extensions later: ./update_extensions.sh"
log "Access ComfyUI at: http://$(hostname -I | awk '{print $1}'):8188"
