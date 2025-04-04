#!/bin/bash
# Extensions and tools setup for ComfyUI on Vast.ai with debugging

# Log function with timestamps
log() {
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1"
}

DEBUG_LOG="/workspace/wan_debug.log"
echo "" > $DEBUG_LOG  # Clear debug log

log "Starting ComfyUI extensions setup (DEBUG MODE)..."
log "This script will install WAN 2.1 and other extensions"

# Print system info
log "System information:" | tee -a $DEBUG_LOG
uname -a >> $DEBUG_LOG
df -h >> $DEBUG_LOG
echo "Python version:" >> $DEBUG_LOG
python --version >> $DEBUG_LOG
echo "Pip version:" >> $DEBUG_LOG
pip --version >> $DEBUG_LOG
echo "Git version:" >> $DEBUG_LOG
git --version >> $DEBUG_LOG

# Configure git with debugging
log "Configuring git..." | tee -a $DEBUG_LOG
git config --global url."https://".insteadOf git://
git config --global --list >> $DEBUG_LOG
# Prevent git from asking for credentials
export GIT_TERMINAL_PROMPT=0
export GIT_SSL_NO_VERIFY=1

# Check if ComfyUI is installed
if [ ! -d "/workspace/ComfyUI" ]; then
  log "ERROR: ComfyUI directory not found. Please run setup_comfyui.sh first." | tee -a $DEBUG_LOG
  exit 1
fi

log "Installing WAN 2.1 Suite (with debugging)..." | tee -a $DEBUG_LOG
mkdir -p /workspace/ComfyUI/custom_nodes
cd /workspace/ComfyUI/custom_nodes
log "Current directory: $(pwd)" | tee -a $DEBUG_LOG
log "Cloning WAN 2.1 repository..." | tee -a $DEBUG_LOG

# Clone with full debug output
git clone https://github.com/MoonRide303/ComfyUI-WAN-Suite.git 2>&1 | tee -a $DEBUG_LOG

if [ ! -d "ComfyUI-WAN-Suite" ]; then
  log "ERROR: Git clone failed! Trying alternative approach..." | tee -a $DEBUG_LOG
  # Try curl as alternative
  log "Downloading ZIP file instead..." | tee -a $DEBUG_LOG
  curl -L https://github.com/MoonRide303/ComfyUI-WAN-Suite/archive/refs/heads/main.zip -o wan-suite.zip 2>&1 | tee -a $DEBUG_LOG
  unzip -q wan-suite.zip 2>&1 | tee -a $DEBUG_LOG
  rm wan-suite.zip
  mv ComfyUI-WAN-Suite-main ComfyUI-WAN-Suite
fi

if [ -d "ComfyUI-WAN-Suite" ]; then
  log "WAN 2.1 directory created successfully" | tee -a $DEBUG_LOG
  cd ComfyUI-WAN-Suite
  log "Installing WAN 2.1 requirements..." | tee -a $DEBUG_LOG
  pip install -r requirements.txt 2>&1 | tee -a $DEBUG_LOG
else
  log "ERROR: Failed to create WAN 2.1 directory!" | tee -a $DEBUG_LOG
fi

# Download WAN 2.1 model with debugging
log "Setting up WAN 2.1 model..." | tee -a $DEBUG_LOG
mkdir -p /workspace/ComfyUI/models/wan_models
cd /workspace/ComfyUI/models/wan_models
log "Current directory: $(pwd)" | tee -a $DEBUG_LOG

log "Downloading WAN 2.1 model (with debugging)..." | tee -a $DEBUG_LOG
TEMP_MODEL_FILE="wan_v2_1.pth.tmp"
MODEL_FILE="wan_v2_1.pth"

# Remove any existing empty file
if [ -f "$MODEL_FILE" ] && [ ! -s "$MODEL_FILE" ]; then
  log "Removing existing empty model file" | tee -a $DEBUG_LOG
  rm "$MODEL_FILE"
fi

log "Trying wget download..." | tee -a $DEBUG_LOG
wget -v https://huggingface.co/casmirc/wan_v2_1/resolve/main/wan_v2_1.pth -O $TEMP_MODEL_FILE 2>&1 | tee -a $DEBUG_LOG

if [ ! -s "$TEMP_MODEL_FILE" ]; then
  log "wget failed, trying curl..." | tee -a $DEBUG_LOG
  curl -L https://huggingface.co/casmirc/wan_v2_1/resolve/main/wan_v2_1.pth -o $TEMP_MODEL_FILE 2>&1 | tee -a $DEBUG_LOG
fi

if [ -s "$TEMP_MODEL_FILE" ]; then
  log "Model download successful, renaming to final filename" | tee -a $DEBUG_LOG
  mv $TEMP_MODEL_FILE $MODEL_FILE
  log "Model file size: $(du -h $MODEL_FILE | cut -f1)" | tee -a $DEBUG_LOG
else
  log "ERROR: Failed to download model!" | tee -a $DEBUG_LOG
fi

# Create symlinks for model discovery
log "Setting up model symlinks..." | tee -a $DEBUG_LOG
mkdir -p /workspace/ComfyUI/models/checkpoints
ln -sf /workspace/ComfyUI/models/wan_models /workspace/ComfyUI/models/checkpoints/wan_models

# Check if things are installed
log "Verifying installation..." | tee -a $DEBUG_LOG
echo "WAN 2.1 Suite extension exists: $(test -d /workspace/ComfyUI/custom_nodes/ComfyUI-WAN-Suite && echo 'YES' || echo 'NO')" | tee -a $DEBUG_LOG
echo "WAN 2.1 model exists: $(test -f /workspace/ComfyUI/models/wan_models/wan_v2_1.pth && echo 'YES' || echo 'NO')" | tee -a $DEBUG_LOG
echo "WAN 2.1 model size: $(du -h /workspace/ComfyUI/models/wan_models/wan_v2_1.pth 2>/dev/null | cut -f1 || echo 'ERROR')" | tee -a $DEBUG_LOG
echo "Symlink exists: $(test -L /workspace/ComfyUI/models/checkpoints/wan_models && echo 'YES' || echo 'NO')" | tee -a $DEBUG_LOG

log "WAN 2.1 installation complete. Check $DEBUG_LOG for detailed logs."
log "You need to restart ComfyUI to see WAN 2.1 nodes:"
log "pkill -f \"python main.py\" && cd /workspace/ComfyUI && python main.py --listen 0.0.0.0 --port 8188 --enable-cors-header"
