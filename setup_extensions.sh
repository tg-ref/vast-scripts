#!/bin/bash
# Robust ComfyUI Extensions Installation Script
# Designed for reliable extension management

# Strict error handling
set -Eeo pipefail

# Logging function
log() {
    local level="${2:-INFO}"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local message="[${timestamp}] [${level}] $1"
    
    echo "$message"
    echo "$message" >> "/workspace/comfyui_extensions.log"
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
    } >> "/workspace/comfyui_extensions.log"
    
    exit 1
}

# Trap any errors
trap 'error_exit "Command failed: $BASH_COMMAND"' ERR

# List of extensions to install
EXTENSIONS=(
    "https://github.com/MoonRide303/ComfyUI-WAN-Suite.git"
    # Add more extensions as needed
)

# Install a single extension
install_extension() {
    local repo_url="$1"
    local repo_name=$(basename "$repo_url" .git)
    local install_path="/workspace/ComfyUI/custom_nodes/$repo_name"

    log "Installing extension: $repo_name" "INFO"

    # Remove existing extension
    if [ -d "$install_path" ]; then
        log "Removing existing $repo_name" "INFO"
        rm -rf "$install_path"
    fi

    # Clone with multiple retry attempts
    for _ in {1..3}; do
        if git clone "$repo_url" "$install_path"; then
            break
        fi
        log "Failed to clone $repo_name. Retrying..." "WARN"
        sleep 10
    done

    # Install requirements if exists
    if [ -f "$install_path/requirements.txt" ]; then
        log "Installing requirements for $repo_name" "INFO"
        for _ in {1..3}; do
            if python3 -m pip install -r "$install_path/requirements.txt"; then
                break
            fi
            log "Requirements installation failed. Retrying..." "WARN"
            sleep 10
        done
    fi
}

# Download and setup specialized models
setup_specialized_models() {
    log "Setting up specialized models..." "INFO"

    # WAN 2.1 Model Setup
    local wan_model_dir="/workspace/ComfyUI/models/wan_models"
    local wan_model_url="https://huggingface.co/casmirc/wan_v2_1/resolve/main/wan_v2_1.pth"
    local wan_model_path="${wan_model_dir}/wan_v2_1.pth"

    # Create directories
    mkdir -p "$wan_model_dir"
    mkdir -p "/workspace/ComfyUI/models/checkpoints"

    # Download model with multiple retry
    for _ in {1..3}; do
        if curl -L "$wan_model_url" -o "$wan_model_path"; then
            log "WAN 2.1 model downloaded successfully" "SUCCESS"
            
            # Create symlinks
            ln -sf "$wan_model_dir" "/workspace/ComfyUI/models/checkpoints/wan_models"
            break
        fi
        log "Model download failed. Retrying..." "WARN"
        sleep 10
    done
}

# Main execution function
main() {
    log "Starting ComfyUI Extensions Setup" "INFO"

    # Ensure we're in the right directory
    cd "/workspace/ComfyUI" || error_exit "ComfyUI directory not found"

    # Create custom nodes directory
    mkdir -p custom_nodes

    # Install each extension
    for ext_url in "${EXTENSIONS[@]}"; do
        install_extension "$ext_url"
    done

    # Setup specialized models
    setup_specialized_models

    log "ComfyUI extensions setup completed successfully!" "SUCCESS"
}

# Execute main function
main
