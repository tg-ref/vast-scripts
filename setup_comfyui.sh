#!/bin/bash
# Robust ComfyUI + WAN 2.1 setup script for Vast.ai RTX 3090 instances

# Log files
SETUP_LOG="/workspace/comfyui_setup.log"
COMFY_LOG="/workspace/comfyui.log"
STATUS_FILE="/workspace/comfyui_status.log"

# Clear previous logs
rm -f $SETUP_LOG $STATUS_FILE

# Log function
log() {
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a $SETUP_LOG
  # Also add important messages to status file
  if [[ "$2" == "status" ]]; then
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> $STATUS_FILE
  fi
}

log "==== ComfyUI with WAN 2.1 Installation Started ====" "status"

# Check GPU and CUDA compatibility
log "Checking GPU and CUDA compatibility..." "status"
if command -v nvidia-smi &> /dev/null; then
  GPU_INFO=$(nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader)
  log "GPU detected: $GPU_INFO" "status"
  
  # Check CUDA availability with PyTorch
  CUDA_AVAILABLE=$(python -c "import torch; print(torch.cuda.is_available())")
  CUDA_VERSION=$(python -c "import torch; print(torch.version.cuda if torch.cuda.is_available() else 'N/A')")
  log "CUDA available: $CUDA_AVAILABLE, CUDA version: $CUDA_VERSION" "status"
  
  if [ "$CUDA_AVAILABLE" = "True" ]; then
    USE_CPU="false"
    log "Will use GPU for ComfyUI" "status"
  else
    USE_CPU="true"
    log "CUDA is not available with PyTorch, will use CPU mode" "status"
  fi
else
  log "No NVIDIA GPU detected, will use CPU mode" "status"
  USE_CPU="true"
fi

# Clean install of ComfyUI
log "Removing any existing ComfyUI installation..."
rm -rf /workspace/ComfyUI

log "Cloning fresh ComfyUI repository..." "status"
cd /workspace
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI
log "Installing ComfyUI dependencies..."
pip install -r requirements.txt

# Modify ComfyUI for CPU mode if needed
if [ "$USE_CPU" = "true" ]; then
  log "Configuring ComfyUI for CPU-only mode..." "status"
  # Create backup of the original file
  cp comfy/model_management.py comfy/model_management.py.backup
  
  # Use awk for more reliable file editing
  awk '{
    if ($0 ~ /def get_torch_device\(\):/) {
      print $0;
      print "    return torch.device(\"cpu\")  # Force CPU mode";
    } 
    else if ($0 ~ /return torch.device\(torch.cuda.current_device\(\)\)/) {
      print "    # " $0;
    } 
    else {
      print $0;
    }
  }' comfy/model_management.py.backup > comfy/model_management.py
  
  log "Modified model_management.py for CPU-only operation"
fi

# Install WAN 2.1 Suite
log "Installing WAN 2.1 Suite..." "status"
mkdir -p /workspace/ComfyUI/custom_nodes
cd /workspace/ComfyUI/custom_nodes
git clone https://github.com/MoonRide303/ComfyUI-WAN-Suite.git
cd ComfyUI-WAN-Suite
pip install -r requirements.txt

# Create model directories
log "Setting up model directories..."
mkdir -p /workspace/ComfyUI/models/wan_models
mkdir -p /workspace/ComfyUI/models/checkpoints

# Download WAN 2.1 model
log "Downloading WAN 2.1 model..." "status"
cd /workspace/ComfyUI/models/wan_models
wget --no-verbose --show-progress https://huggingface.co/casmirc/wan_v2_1/resolve/main/wan_v2_1.pth

# Create symlinks for model discovery
log "Setting up model symlinks..."
ln -sf /workspace/ComfyUI/models/wan_models /workspace/ComfyUI/models/checkpoints/wan_models

# Start ComfyUI
log "Starting ComfyUI..." "status"
cd /workspace/ComfyUI

# Start with appropriate options based on GPU availability
if [ "$USE_CPU" = "true" ]; then
  log "Starting in CPU mode (this will be slower but more compatible)..." "status"
  nohup python main.py --listen 0.0.0.0 --port 8188 --enable-cors-header --cpu > $COMFY_LOG 2>&1 &
else
  # For RTX 3090, we can enable xformers for better performance
  log "Installing xformers for better performance..."
  pip install xformers
  log "Starting with GPU acceleration and xformers optimizations..." "status"
  nohup python main.py --listen 0.0.0.0 --port 8188 --enable-cors-header > $COMFY_LOG 2>&1 &
fi

# Wait for startup
log "Waiting for ComfyUI to start (15 seconds)..."
sleep 15

# Check if ComfyUI is running
if pgrep -f "python main.py" > /dev/null; then
  log "ComfyUI started successfully!" "status"
  
  # Get instance IP
  INSTANCE_IP=$(hostname -I | awk '{print $1}')
  
  log "ComfyUI should now be accessible via:" "status"
  log "- http://${INSTANCE_IP}:8188" "status"
  log "- Also through the Vast.ai portal interface" "status"
  
  # Instructions for WAN 2.1 usage
  log "WAN 2.1 is installed and ready to use." "status"
  log "WAN 2.1 model path: /workspace/ComfyUI/models/wan_models/wan_v2_1.pth" "status"
  log "To use it:" "status"
  log "1. Right-click on canvas and search for 'WAN' nodes" "status"
  log "2. WAN nodes should be available in the menu" "status"
  
  # Mark as complete
  echo "success" > /workspace/comfyui_setup_complete
else
  log "ERROR: ComfyUI failed to start! Checking logs..." "status"
  tail -n 30 $COMFY_LOG > /workspace/comfyui_error.log
  log "Error details saved to /workspace/comfyui_error.log" "status"
  
  # Try alternate startup method if first attempt failed
  log "Attempting alternate startup method..." "status"
  cd /workspace/ComfyUI
  pkill -f "python main.py"
  
  # Try with different parameters
  if [ "$USE_CPU" = "true" ]; then
    nohup python main.py --listen 0.0.0.0 --port 8188 --cpu --lowvram > /workspace/comfyui_retry.log 2>&1 &
  else
    nohup python main.py --listen 0.0.0.0 --port 8188 --lowvram > /workspace/comfyui_retry.log 2>&1 &
  fi
  
  sleep 10
  
  if pgrep -f "python main.py" > /dev/null; then
    log "ComfyUI started successfully on second attempt!" "status"
    echo "success_retry" > /workspace/comfyui_setup_complete
  else
    log "Both startup attempts failed. Please check logs and try manual startup." "status"
    echo "failed" > /workspace/comfyui_setup_complete
  fi
fi

# Create a final installation report
log "==== Installation Summary ====" "status"
log "ComfyUI installation: $(test -d /workspace/ComfyUI && echo 'INSTALLED' || echo 'FAILED')" "status"
log "WAN 2.1 extension: $(test -d /workspace/ComfyUI/custom_nodes/ComfyUI-WAN-Suite && echo 'INSTALLED' || echo 'FAILED')" "status"
log "WAN 2.1 model: $(test -f /workspace/ComfyUI/models/wan_models/wan_v2_1.pth && echo 'DOWNLOADED' || echo 'MISSING')" "status"
log "ComfyUI running: $(pgrep -f "python main.py" > /dev/null && echo 'YES' || echo 'NO')" "status"
log "Operating mode: $([ "$USE_CPU" = "true" ] && echo 'CPU (slower)' || echo 'GPU (faster)')" "status"

# Add command to check status
log "To check installation status: cat /workspace/comfyui_status.log" "status"
log "To see ComfyUI logs: tail -f /workspace/comfyui.log" "status"
log "To restart ComfyUI if needed:" "status"
log "  cd /workspace/ComfyUI && pkill -f \"python main.py\" && python main.py --listen 0.0.0.0 --port 8188 --enable-cors-header" "status"

log "Setup process complete." "status"
