#!/bin/bash
# ComfyUI Extensions Setup Script for Vast.ai

# Log function
log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1"
}

# Error handling function
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Ensure we're in the right directory
cd /workspace/ComfyUI || error_exit "ComfyUI directory not found"

# Create custom nodes directory if it doesn't exist
mkdir -p custom_nodes

# List of extensions to install
EXTENSIONS=(
    "https://github.com/MoonRide303/ComfyUI-WAN-Suite.git"
    # Add more extension repositories here
)

# Install each extension
for ext_url in "${EXTENSIONS[@]}"; do
    # Extract repository name
    repo_name=$(basename "$ext_url" .git)
    
    log "Processing extension: $repo_name"
    
    # Remove existing extension if it exists
    if [ -d "custom_nodes/$repo_name" ]; then
        log "Removing existing $repo_name"
        rm -rf "custom_nodes/$repo_name"
    fi
    
    # Clone the extension
    log "Cloning $ext_url"
    git clone "$ext_url" "custom_nodes/$repo_name" || {
        log "Failed to clone $ext_url. Trying alternative download method..."
        
        # Alternative download method using curl
        repo_owner=$(echo "$ext_url" | cut -d'/' -f4)
        repo=$(echo "$ext_url" | cut -d'/' -f5 | cut -d'.' -f1)
        zip_url="https://github.com/$repo_owner/$repo/archive/refs/heads/main.zip"
        
        curl -L "$zip_url" -o "$repo_name.zip"
        unzip -q "$repo_name.zip" -d "custom_nodes"
        mv "custom_nodes/$repo_name-main" "custom_nodes/$repo_name"
        rm "$repo_name.zip"
    }
    
    # Check for requirements file and install if exists
    if [ -f "custom_nodes/$repo_name/requirements.txt" ]; then
        log "Installing requirements for $repo_name"
        pip install -r "custom_nodes/$repo_name/requirements.txt"
    fi
done

# Special handling for WAN Suite model
log "Setting up WAN 2.1 model..."
mkdir -p /workspace/ComfyUI/models/wan_models
cd /workspace/ComfyUI/models/wan_models

# Download WAN 2.1 model
MODEL_URL="https://huggingface.co/casmirc/wan_v2_1/resolve/main/wan_v2_1.pth"
MODEL_FILE="wan_v2_1.pth"

log "Downloading WAN 2.1 model..."
if wget -O "$MODEL_FILE" "$MODEL_URL"; then
    log "WAN 2.1 model downloaded successfully"
else
    log "Wget failed, trying curl..."
    curl -L "$MODEL_URL" -o "$MODEL_FILE"
fi

# Verify model download
if [ -s "$MODEL_FILE" ]; then
    log "Model file size: $(du -h "$MODEL_FILE" | cut -f1)"
    
    # Create symlinks for model discovery
    mkdir -p /workspace/ComfyUI/models/checkpoints
    ln -sf /workspace/ComfyUI/models/wan_models /workspace/ComfyUI/models/checkpoints/wan_models
else
    log "ERROR: Failed to download WAN 2.1 model"
fi

log "ComfyUI extensions setup complete!"
