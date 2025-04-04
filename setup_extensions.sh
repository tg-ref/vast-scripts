#!/bin/bash
# 🚀 Advanced ComfyUI Extensions Installer
# Robust cloning with multiple fallback strategies

set -euo pipefail

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Error handling function
error_exit() {
    echo "[ERROR] $1" >&2
    exit 1
}

# Workspace and directory setup
WORKSPACE="${WORKSPACE:-/workspace}"
COMFYUI_DIR="$WORKSPACE/ComfyUI"
CUSTOM_NODES_DIR="$COMFYUI_DIR/custom_nodes"

# Create directories
mkdir -p "$CUSTOM_NODES_DIR"

# Cleanup function
cleanup() {
    log "🧹 Cleaning up previous extensions..."
    rm -rf "$CUSTOM_NODES_DIR"/*
}

# Manual download fallback for challenging repositories
manual_download_extension() {
    local name="$1"
    local repo_url="$2"
    local branch="${3:-main}"
    local download_url=""

    log "🚨 Attempting manual download for $name"

    # Generate download URL for GitHub repository
    if [[ "$repo_url" == *"github.com"* ]]; then
        download_url="${repo_url%\.git}/archive/refs/heads/${branch}.zip"
    else
        error_exit "Unsupported repository type for manual download"
    fi

    # Download and extract
    log "📦 Downloading from $download_url"
    if ! curl -L -o "/tmp/${name}.zip" "$download_url"; then
        error_exit "Failed to download $name"
    fi

    # Extract to custom nodes directory
    if ! unzip -q "/tmp/${name}.zip" -d "$CUSTOM_NODES_DIR"; then
        error_exit "Failed to extract $name"
    fi

    # Rename extracted directory to match extension name
    extracted_dir=$(find "$CUSTOM_NODES_DIR" -maxdepth 1 -type d -name "*${name}*" | head -n 1)
    if [ -n "$extracted_dir" ]; then
        mv "$extracted_dir" "$CUSTOM_NODES_DIR/$name"
    fi

    # Clean up
    rm "/tmp/${name}.zip"
}

# Extension installation function with advanced fallback
install_extension() {
    local name="$1"
    local repo_url="$2"
    local branch="${3:-main}"
    local clone_success=false

    log "🔽 Attempting to install $name from $repo_url"

    # Clone strategies array (most specific to least specific)
    local clone_strategies=(
        # Direct HTTPS clone
        "git clone --depth 1 -b $branch $repo_url $CUSTOM_NODES_DIR/$name"
        
        # No terminal prompt strategy
        "GIT_TERMINAL_PROMPT=0 git clone --depth 1 -b $branch $repo_url $CUSTOM_NODES_DIR/$name"
        
        # Convert SSH to HTTPS
        "git clone --depth 1 -b $branch $(echo $repo_url | sed -e 's/git@github\.com:/https:\/\/github.com\//' -e 's/\.git$//')"
        
        # HTTP fallback
        "git clone --depth 1 -b $branch $(echo $repo_url | sed 's/https:\/\//http:\/\//')"
    )

    # Try each clone strategy
    for strategy in "${clone_strategies[@]}"; do
        log "🔄 Trying clone strategy: $strategy"
        
        if timeout 300 bash -c "$strategy" >/dev/null 2>&1; then
            clone_success=true
            break
        fi
    done

    # If all clone strategies fail, attempt manual download
    if [ "$clone_success" = false ]; then
        log "❌ Clone strategies failed. Attempting manual download..."
        manual_download_extension "$name" "$repo_url" "$branch"
    fi

    # Install Python dependencies
    if [ -f "$CUSTOM_NODES_DIR/$name/requirements.txt" ]; then
        log "📦 Installing Python dependencies for $name"
        timeout 600 pip install --no-cache-dir -r "$CUSTOM_NODES_DIR/$name/requirements.txt" || {
            log "⚠️ Warning: Some dependencies for $name failed to install"
        }
    fi

    # Verify installation
    if [ ! -f "$CUSTOM_NODES_DIR/$name/__init__.py" ]; then
        log "⚠️ $name may be incomplete (missing __init__.py)"
    else
        log "✅ $name installed successfully"
    fi
}

# Main installation process
main() {
    # Trap errors
    trap 'error_exit "Script failed at line $LINENO"' ERR

    # Initial cleanup
    cleanup

    # Verify essential tools
    command -v git >/dev/null 2>&1 || error_exit "Git is not installed"
    command -v pip >/dev/null 2>&1 || error_exit "Pip is not installed"
    command -v curl >/dev/null 2>&1 || error_exit "Curl is not installed"
    command -v unzip >/dev/null 2>&1 || error_exit "Unzip is not installed"

    # Configure Git to avoid prompts
    git config --global core.askpass true
    export GIT_TERMINAL_PROMPT=0

    log "🔧 Installing core extensions..."
    
    # List of extensions with their repositories
    local extensions=(
        "ComfyUI-Manager:https://github.com/ltdrdata/ComfyUI-Manager.git"
        "ComfyUI-Impact-Pack:https://github.com/ltdrdata/ComfyUI-Impact-Pack.git"
        "ComfyUI-WAN-Suite:https://github.com/WASasquatch/ComfyUI-WAN-Suite.git"
        "comfyui-nodes-base:https://github.com/Acly/comfyui-nodes-base.git"
        "ComfyUI_IPAdapter_plus:https://github.com/cubiq/ComfyUI_IPAdapter_plus.git"
        "comfyui-nodes-rgthree:https://github.com/rgthree/comfyui-nodes-rgthree.git"
        "ComfyUI_ControlNet:https://github.com/Fannovel16/comfyui_controlnet_aux.git"
        "ComfyUI-VideoHelperSuite:https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"
        "ComfyUI-WanVideoWrapper:https://github.com/kijai/ComfyUI-WanVideoWrapper.git"
    )

    # Install each extension
    for ext in "${extensions[@]}"; do
        IFS=':' read -r name repo <<< "$ext"
        install_extension "$name" "$repo"
    done

    # Global dependency installation
    log "📚 Installing global Python dependencies..."
    pip install --upgrade pip

    # Essential dependencies for most ComfyUI extensions
    local global_deps=(
        "opencv-python"
        "onnxruntime"
        "onnx"
        "transformers"
        "accelerate"
        "safetensors"
        "insightface"
        "timm"
        "fairscale"
        "prettytable"
        "ultralytics"
    )

    for dep in "${global_deps[@]}"; do
        pip install --no-cache-dir "$dep" || {
            log "⚠️ Warning: Failed to install $dep"
        }
    done

    # Final summary
    log "📂 Installed Extensions:"
    for dir in "$CUSTOM_NODES_DIR"/*; do
        if [ -d "$dir" ]; then
            if [ -f "$dir/__init__.py" ]; then
                echo "  ✅ $(basename "$dir")"
            else
                echo "  ⚠️ $(basename "$dir") (possibly incomplete)"
            fi
        fi
    done

    log "🚀 ComfyUI extensions installation complete!"
    log "▶ Ready to start ComfyUI"
}

# Run the main function
main
