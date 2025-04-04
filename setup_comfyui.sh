#!/bin/bash
# Robust ComfyUI Core Installation Script
# Designed for reliable setup across Vast.ai instances
# Modified to work with Docker containers

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

# Create startup script
create_startup_script() {
    log "Creating startup script..." "INFO"
    
    cat > /workspace/start_comfyui.sh << 'EOL'
#!/bin/bash
# ComfyUI Startup Script for Docker/Vast.ai environments

# Logging function
log() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local message="[${timestamp}] $1"
    echo "$message"
    echo "$message" >> /workspace/comfyui_startup.log
}

log "Starting ComfyUI..."

# Check if ComfyUI is already running
if pgrep -f "python.*main.py" > /dev/null; then
    log "ComfyUI is already running. Terminating existing process..."
    pkill -f "python.*main.py"
    sleep 5
fi

# Navigate to ComfyUI directory
cd /workspace/ComfyUI || {
    log "ERROR: ComfyUI directory not found"
    exit 1
}

# Start ComfyUI
log "Starting ComfyUI server..."
python3 main.py --listen 0.0.0.0 --port 8188 --enable-cors-header
EOL

    chmod +x /workspace/start_comfyui.sh
    
    # Also create a background version for persistent running
    cat > /workspace/start_comfyui_background.sh << 'EOL'
#!/bin/bash
# ComfyUI Background Startup Script for Docker/Vast.ai environments

# Logging function
log() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local message="[${timestamp}] $1"
    echo "$message"
    echo "$message" >> /workspace/comfyui_startup.log
}

log "Starting ComfyUI in background mode..."

# Check if ComfyUI is already running
if pgrep -f "python.*main.py" > /dev/null; then
    log "ComfyUI is already running. Terminating existing process..."
    pkill -f "python.*main.py"
    sleep 5
fi

# Navigate to ComfyUI directory
cd /workspace/ComfyUI || {
    log "ERROR: ComfyUI directory not found"
    exit 1
}

# Start ComfyUI in background with nohup
log "Starting ComfyUI server in background..."
nohup python3 main.py --listen 0.0.0.0 --port 8188 --enable-cors-header > /workspace/comfyui_output.log 2>&1 &

# Check if process started successfully
sleep 5
if pgrep -f "python.*main.py" > /dev/null; then
    log "ComfyUI started successfully in background"
    IP_ADDRESS=$(hostname -I | awk '{print $1}')
    log "ComfyUI is accessible at: http://${IP_ADDRESS}:8188"
else
    log "ERROR: Failed to start ComfyUI"
fi
EOL

    chmod +x /workspace/start_comfyui_background.sh
}

# Setup basic extensions without requiring GitHub authentication
setup_basic_extensions() {
    log "Setting up basic extensions..." "INFO"
    
    # Create custom_nodes directory if it doesn't exist
    mkdir -p /workspace/ComfyUI/custom_nodes
    
    # List of public extensions to install
    local extensions=(
        "https://github.com/ltdrdata/ComfyUI-Manager.git"
    )
    
    # Clone each extension
    for extension in "${extensions[@]}"; do
        local extension_name=$(basename "$extension" .git)
        local target_dir="/workspace/ComfyUI/custom_nodes/$extension_name"
        
        log "Installing extension: $extension_name" "INFO"
        
        # Skip if already exists
        if [ -d "$target_dir" ]; then
            log "Extension $extension_name already exists, skipping." "INFO"
            continue
        fi
        
        # Clone with multiple retry attempts
        for _ in {1..3}; do
            if git clone "$extension" "$target_dir"; then
                break
            fi
            log "Extension clone failed. Retrying..." "WARN"
            sleep 5
        done
        
        # Install requirements if present
        if [ -f "$target_dir/requirements.txt" ]; then
            log "Installing requirements for $extension_name" "INFO"
            python3 -m pip install -r "$target_dir/requirements.txt" || log "Failed to install requirements for $extension_name" "WARN"
        fi
    done
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
    setup_basic_extensions
    
    # Print final instructions
    IP_ADDRESS=$(hostname -I | awk '{print $1}')
    log "ComfyUI setup completed successfully!" "SUCCESS"
    log "To start ComfyUI in foreground mode: /workspace/start_comfyui.sh" "INFO"
    log "To start ComfyUI in background mode: /workspace/start_comfyui_background.sh" "INFO"
    log "ComfyUI will be accessible at: http://${IP_ADDRESS}:8188" "INFO"
}

# Execute main function
main
