#!/bin/bash
# Extensions and tools setup for ComfyUI on Vast.ai

# Log function
log() {
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1"
}

log "Starting ComfyUI extensions setup..."

# Configure git to use https instead of git protocol
git config --global url."https://".insteadOf git://
# Prevent git from asking for credentials
export GIT_TERMINAL_PROMPT=0

# Check if ComfyUI is installed
if [ ! -d "/workspace/ComfyUI" ]; then
  log "ERROR: ComfyUI directory not found. Please run setup_comfyui.sh first."
  exit 1
fi

# Create custom_nodes directory if it doesn't exist
mkdir -p /workspace/ComfyUI/custom_nodes

# Install WAN 2.1 Suite
log "Installing WAN 2.1 Suite..."
cd /workspace/ComfyUI/custom_nodes
git clone https://github.com/MoonRide303/ComfyUI-WAN-Suite.git
cd ComfyUI-WAN-Suite
pip install -r requirements.txt

# Download WAN 2.1 model
log "Downloading WAN 2.1 model..."
mkdir -p /workspace/ComfyUI/models/wan_models
cd /workspace/ComfyUI/models/wan_models
wget --no-verbose https://huggingface.co/casmirc/wan_v2_1/resolve/main/wan_v2_1.pth

# Create symlinks for model discovery
log "Setting up model symlinks..."
ln -sf /workspace/ComfyUI/models/wan_models /workspace/ComfyUI/models/checkpoints/wan_models

# Install ComfyUI Manager (for easy installation of other extensions)
log "Installing ComfyUI Manager..."
cd /workspace/ComfyUI/custom_nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager.git

# Install ControlNet
log "Installing ControlNet extension..."
cd /workspace/ComfyUI/custom_nodes
git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git
cd comfyui_controlnet_aux
pip install -r requirements.txt

# Install Impact Pack
log "Installing Impact Pack..."
cd /workspace/ComfyUI/custom_nodes
git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git
cd ComfyUI-Impact-Pack
pip install -r requirements.txt
python install.py

log "Extensions setup complete!"
log "To start ComfyUI with all extensions, run: cd /workspace/ComfyUI && python main.py --listen 0.0.0.0 --port 8188 --enable-cors-header"
