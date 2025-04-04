#!/bin/bash
# Robust ComfyUI Startup Script for Vast.ai Docker Environments
# https://github.com/DnsSrinath/vast-scripts

# Logging function
log() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[${timestamp}] $1" | tee -a /workspace/comfyui_startup.log
}

# Error handling function
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Ensure we're in the correct directory
cd /workspace/ComfyUI || error_exit "Cannot change to ComfyUI directory"

# Log script start
log "Starting ComfyUI startup script..."

# Detect GPU availability
if command -v nvidia-smi &> /dev/null; then
    log "NVIDIA GPU detected"
    # Log GPU information
    nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader
else
    log "No NVIDIA GPU detected. Running in CPU mode."
fi

# Kill any existing ComfyUI processes
log "Checking and terminating existing ComfyUI processes..."
pkill -f "python.*main.py" || true
sleep 3

# Prepare startup configuration
log "Preparing ComfyUI startup configuration..."

# Create extra arguments file
echo "--listen 0.0.0.0 --port 8188 --enable-cors-header" > /workspace/ComfyUI/extra_args.txt
chmod 755 /workspace/ComfyUI/extra_args.txt

# Install or check dependencies
log "Checking dependencies..."
python3 -m pip install torch torchvision torchaudio xformers --quiet || \
    log "Warning: Some dependencies could not be installed, but ComfyUI may still work."

# Create persistent startup script if it doesn't exist
if [ ! -f "/workspace/comfyui_persistent_start.sh" ]; then
    log "Creating persistent startup script..."
    cat > /workspace/comfyui_persistent_start.sh << 'EOL'
#!/bin/bash
# Persistent ComfyUI Startup Script for Docker Environments

# Logging function
log() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local message="[${timestamp}] $1"
    echo "$message" >> /workspace/comfyui_persistent.log
    echo "$message"
}

# Main function to start ComfyUI
start_comfyui() {
    cd /workspace/ComfyUI || {
        log "ERROR: ComfyUI directory not found"
        return 1
    }
    
    # Kill any existing ComfyUI processes
    pkill -f "python.*main.py" || true
    sleep 2
    
    # Start ComfyUI
    log "Starting ComfyUI..."
    nohup python3 main.py --listen 0.0.0.0 --port 8188 --enable-cors-header > /workspace/comfyui_output.log 2>&1 &
    
    # Check if process started successfully
    sleep 5
    if pgrep -f "python.*main.py" > /dev/null; then
        log "ComfyUI started successfully"
        log "ComfyUI is accessible at: http://$(hostname -I | awk '{print $1}'):8188"
        return 0
    else
        log "ERROR: Failed to start ComfyUI"
        return 1
    }
}

# Monitor and restart if necessary
monitor_and_restart() {
    while true; do
        if ! pgrep -f "python.*main.py" > /dev/null; then
            log "ComfyUI is not running. Attempting to restart..."
            start_comfyui
        fi
        sleep 60
    done
}

# Start ComfyUI initially
start_comfyui

# Start the monitoring loop
monitor_and_restart
EOL
    chmod +x /workspace/comfyui_persistent_start.sh
fi

# Choose startup mode based on argument
if [ "$1" == "background" ]; then
    # Start in background mode with monitoring
    log "Starting ComfyUI in background mode with automatic monitoring..."
    nohup /workspace/comfyui_persistent_start.sh > /workspace/comfyui_wrapper.log 2>&1 &
    
    # Wait a moment and check if it started
    sleep 5
    if pgrep -f "python.*main.py" > /dev/null; then
        log "ComfyUI started successfully in background mode"
        log "Access ComfyUI at: http://$(hostname -I | awk '{print $1}'):8188"
        log "View logs with: tail -f /workspace/comfyui_output.log"
    else
        log "WARNING: ComfyUI may have failed to start. Check logs."
        log "View logs with: tail -f /workspace/comfyui_wrapper.log"
    fi
else
    # Start in foreground mode
    log "Starting ComfyUI in foreground mode..."
    log "Access ComfyUI at: http://$(hostname -I | awk '{print $1}'):8188"
    python3 main.py --listen 0.0.0.0 --port 8188 --enable-cors-header
fi
