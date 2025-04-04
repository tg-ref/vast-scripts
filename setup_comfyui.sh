#!/bin/bash
# Robust ComfyUI Core Installation Script
# Designed for reliable setup across Vast.ai instances

# Strict error handling
set -Eeo pipefail

# Logging function
log() {
    local level="${2:-INFO}"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local message="[${timestamp}] [${level}] $1"
    
    echo "$message"
    echo "$message" >> "/workspace/comfyui_installation.log"
}

# Comprehensive error handling
error_exit() {
    log "CRITICAL ERROR: $1" "ERROR"
    
    # Capture system diagnostics
    {
        echo "System Diagnostics:"
        echo "Hostname: $(hostname)"
        echo "Current User: $(whoami)"
        echo "Current Directory: $(pwd)"
        echo "Disk Space:"
        df -h
        echo "Python Information:"
        which python3
        python3 --version
    } >> "/workspace/comfyui_installation.log"
    
    exit 1
}

# Trap any errors
trap 'error_exit "Command failed: $BASH_COMMAND"' ERR

# Prepare system environment
prepare_system() {
    log "Preparing system environment..." "INFO"
    
    # Ensure workspace exists
    mkdir -p /workspace
    cd /workspace

    # Update package lists with multiple retry
    for _ in {1..3}; do
        if sudo apt-get update; then
            break
        fi
        log "Package list update failed. Retrying..." "WARN"
        sleep 5
    done

    # Install essential packages
    local packages=(
        "git" "wget" "curl" "unzip"
        "python3" "python3-pip" "python3-venv"
        "build-essential" "software-properties-common"
    )

    for pkg in "${packages[@]}"; do
        for _ in {1..3}; do
            if sudo apt-get install -y "$pkg"; then
                break
            fi
            log "Failed to install $pkg. Retrying..." "WARN"
            sleep 5
        done
    done

    # Upgrade pip
    python3 -m pip install --upgrade pip || log "Pip upgrade failed" "WARN"
}

# Clone and setup ComfyUI
setup_comfyui() {
    log "Setting up ComfyUI..." "INFO"
    
    # Remove existing installation if present
    if [ -d "/workspace/ComfyUI" ]; then
        log "Removing existing ComfyUI installation..." "INFO"
        rm -rf "/workspace/ComfyUI"
    fi

    # Clone ComfyUI with multiple retry attempts
    for _ in {1..3}; do
        if git clone https://github.com/comfyanonymous/ComfyUI.git; then
            break
        fi
        log "ComfyUI clone failed. Retrying..." "WARN"
        sleep 10
    done

    # Change to ComfyUI directory
    cd ComfyUI

    # Install Python dependencies with robust error handling
    for _ in {1..3}; do
        if python3 -m pip install -r requirements.txt; then
            break
        fi
        log "Requirements installation failed. Retrying..." "WARN"
        sleep 10
    done
}

# Create necessary directories
create_model_directories() {
    log "Creating model directories..." "INFO"
    
    local model_dirs=(
        "/workspace/ComfyUI/models/checkpoints"
        "/workspace/ComfyUI/models/loras"
        "/workspace/ComfyUI/models/upscale_models"
        "/workspace/ComfyUI/models/clip"
        "/workspace/ComfyUI/models/vae"
        "/workspace/ComfyUI/custom_nodes"
    )

    for dir in "${model_dirs[@]}"; do
        mkdir -p "$dir"
        chmod 755 "$dir"
    done
}

# Install GPU dependencies
install_gpu_dependencies() {
    log "Checking and installing GPU dependencies..." "INFO"
    
    # Detect GPU
    if command -v nvidia-smi &> /dev/null; then
        log "NVIDIA GPU detected. Installing GPU dependencies..." "INFO"
        
        # GPU-specific package installation
        local gpu_packages=(
            "torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121"
            "xformers"
        )

        for package in "${gpu_packages[@]}"; do
            for _ in {1..3}; do
                if python3 -m pip install $package; then
                    break
                fi
                log "Failed to install $package. Retrying..." "WARN"
                sleep 10
            done
        done
    else
        log "No NVIDIA GPU detected. Continuing with CPU setup..." "WARN"
    fi
}

# Create persistent startup script
create_startup_script() {
    log "Creating persistent startup script..." "INFO"
    
    cat > /workspace/comfyui_persistent_start.sh << 'EOL'
#!/bin/bash
# Persistent ComfyUI Startup Script

# Logging function
log() {
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] $1" >> /workspace/comfyui_persistent.log
}

# Main startup function
start_comfyui() {
    cd /workspace/ComfyUI
    
    # Kill any existing ComfyUI processes
    pkill -f "python.*main.py" || true
    
    # Start ComfyUI with nohup to keep running
    nohup python3 main.py --listen 0.0.0.0 --port 8188 --enable-cors-header >> /workspace/comfyui_output.log 2>&1 &
    
    # Wait and verify startup
    sleep 10
    
    if pgrep -f "python.*main.py" > /dev/null; then
        log "ComfyUI started successfully"
    else
        log "Failed to start ComfyUI"
    fi
}

# Restart on exit
while true; do
    start_comfyui
    
    # Wait before potential restart
    sleep 60
done
EOL

    chmod +x /workspace/comfyui_persistent_start.sh
}

# Create systemd service for persistent startup
create_systemd_service() {
    log "Creating systemd service for persistent startup..." "INFO"
    
    cat > /etc/systemd/system/comfyui.service << 'EOL'
[Unit]
Description=Persistent ComfyUI Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/workspace
ExecStart=/workspace/comfyui_persistent_start.sh
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOL

    # Enable and start the service
    systemctl daemon-reload
    systemctl enable comfyui.service
    systemctl start comfyui.service
}

# Main execution function
main() {
    log "Starting Comprehensive ComfyUI Setup" "INFO"
    
    # Run setup steps
    prepare_system
    setup_comfyui
    create_model_directories
    install_gpu_dependencies
    create_startup_script
    create_systemd_service

    log "ComfyUI setup completed successfully!" "SUCCESS"
}

# Execute main function
main
