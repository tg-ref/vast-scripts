#!/bin/bash
# Robust ComfyUI Startup and Monitoring Script
# Ensures persistent ComfyUI operation across restarts

# Strict error handling
set -Eeo pipefail

# Global configuration
WORKSPACE="/workspace"
COMFYUI_DIR="${WORKSPACE}/ComfyUI"
STARTUP_LOG="${WORKSPACE}/comfyui_startup.log"
PERSISTENT_LOG="${WORKSPACE}/comfyui_persistent.log"

# Enhanced logging function
log() {
    local level="${2:-INFO}"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local message="[${timestamp}] [${level}] $1"
    
    echo "$message"
    echo "$message" >> "$STARTUP_LOG"
}

# Comprehensive error handling
graceful_exit() {
    local error_message="${1:-Unknown error occurred}"
    log "CRITICAL: $error_message" "ERROR"
    
    # Capture system diagnostics
    {
        echo "System Diagnostics:"
        echo "Hostname: $(hostname)"
        echo "Current User: $(whoami)"
        echo "Current Directory: $(pwd)"
        echo "Disk Space:"
        df -h
        echo "Network Configuration:"
        ip addr
    } >> "$STARTUP_LOG"
    
    exit 1
}

# Trap errors
trap 'graceful_exit "Command failed: $BASH_COMMAND"' ERR

# Create persistent startup script
create_persistent_startup() {
    log "Creating comprehensive persistent startup script..." "INFO"
    
    cat > "${WORKSPACE}/comfyui_persistent_launcher.sh" << 'EOL'
#!/bin/bash
# Comprehensive ComfyUI Persistent Launcher

# Logging function
log() {
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] $1" >> /workspace/comfyui_persistent.log
}

# GPU Readiness Check
check_gpu_ready() {
    if command -v nvidia-smi &> /dev/null; then
        while ! nvidia-smi &> /dev/null; do
            log "Waiting for GPU to be ready..."
            sleep 10
        done
    fi
}

# ComfyUI Startup Function
start_comfyui() {
    local max_retries=3
    local retry_count=0

    while [ $retry_count -lt $max_retries ]; do
        # Ensure we're in the right directory
        cd /workspace/ComfyUI

        # Kill any existing ComfyUI processes
        pkill -f "python.*main.py" || true

        # Start ComfyUI with comprehensive logging
        log "Starting ComfyUI (Attempt $((retry_count +
