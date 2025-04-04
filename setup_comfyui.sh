#!/bin/bash
# Core ComfyUI setup script for Vast.ai

# Log function
log() {
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1"
}

log "Starting core ComfyUI setup..."

# Check GPU
if command -v nvidia-smi &> /dev/null; then
  GPU_INFO=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader)
  log "GPU detected: $GPU_INFO"
  USE_CPU="false"
else
  log "No GPU detected, using CPU mode"
  USE_CPU="true"
fi

# Configure git to use https instead of git protocol
git config --global url."https://".insteadOf git://
# Prevent git from asking for credentials
export GIT_TERMINAL_PROMPT=0

# Remove existing ComfyUI
log "Removing any existing ComfyUI installation..."
rm -rf /workspace/ComfyUI

# Clone ComfyUI
log "Cloning ComfyUI..."
cd /workspace
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI
pip install -r requirements.txt

# Create model directories
log "Setting up directory structure..."
mkdir -p /workspace/ComfyUI/models/checkpoints
mkdir -p /workspace/ComfyUI/models/loras
mkdir -p /workspace/ComfyUI/models/upscale_models
mkdir -p /workspace/ComfyUI/models/clip
mkdir -p /workspace/ComfyUI/models/vae

# Install xformers for better performance if GPU is available
if [ "$USE_CPU" = "false" ]; then
  log "Installing xformers for better performance..."
  pip install xformers
fi

log "Core ComfyUI installation complete!"
log "To start ComfyUI, run: cd /workspace/ComfyUI && python main.py --listen 0.0.0.0 --port 8188 --enable-cors-header"
