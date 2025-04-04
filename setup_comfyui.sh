#!/bin/bash
# ComfyUI Core Setup Script for Vast.ai

# Log function
log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1"
}

# Error handling function
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Ensure we're in the workspace directory
cd /workspace || error_exit "Cannot change to /workspace directory"

# Prepare the environment
log "Preparing ComfyUI installation environment..."

# Update and install essential packages
sudo apt-get update || log "Warning: apt-get update failed"
sudo apt-get install -y \
    wget \
    curl \
    git \
    unzip \
    python3-pip \
    python3-venv || error_exit "Failed to install essential packages"

# Ensure pip is up to date
pip3 install --upgrade pip || log "Warning: Failed to upgrade pip"

# Check for CUDA and GPU
if command -v nvidia-smi &> /dev/null; then
    log "NVIDIA GPU detected"
    GPU_AVAILABLE=true
else
    log "No NVIDIA GPU detected. Will run in CPU mode."
    GPU_AVAILABLE=false
fi

# Remove existing ComfyUI if it exists
if [ -d "/workspace/ComfyUI" ]; then
    log "Removing existing ComfyUI installation..."
    rm -rf /workspace/ComfyUI
fi

# Clone ComfyUI
log "Cloning ComfyUI repository..."
git clone https://github.com/comfyanonymous/ComfyUI.git || error_exit "Failed to clone ComfyUI"

# Navigate to ComfyUI directory
cd ComfyUI

# Install core requirements
log "Installing ComfyUI requirements..."
pip install -r requirements.txt || error_exit "Failed to install ComfyUI requirements"

# Create model directories
log "Creating model directories..."
mkdir -p /workspace/ComfyUI/models/checkpoints
mkdir -p /workspace/ComfyUI/models/loras
mkdir -p /workspace/ComfyUI/models/upscale_models
mkdir -p /workspace/ComfyUI/models/clip
mkdir -p /workspace/ComfyUI/models/vae

# Install GPU-specific dependencies if available
if [ "$GPU_AVAILABLE" = true ]; then
    log "Installing GPU-specific dependencies..."
    pip install torch torchvision torchaudio xformers
fi

# Create a startup configuration file
log "Creating ComfyUI startup configuration..."
cat > extra_args.txt << EOL
--listen 0.0.0.0 --port 8188 --enable-cors-header
EOL
chmod 755 extra_args.txt

# Create a portal configuration file
log "Creating portal configuration..."
cat > /etc/portal.yaml << EOL
instance_portal:
  app_host: localhost
  app_port: 11111
  tls_port: 1111
  app_name: Instance Portal
comfyui:
  app_host: localhost
  app_port: 8188
  tls_port: 8188
  app_name: ComfyUI
EOL

log "ComfyUI core setup complete!"
log "To start ComfyUI, use the startup script or run:"
log "cd /workspace/ComfyUI && python main.py --listen 0.0.0.0 --port 8188 --enable-cors-header"
