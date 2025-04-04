#!/bin/bash
# 🐳 ComfyUI Extensions Installer
# Handles repository cloning without interactive authentication

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

# Extension installation function with multiple clone strategies
install_extension() {
    local name="$1"
    local repo_url="$2"
    local branch="${3:-main}"
    local clone_success=false

    log "🔽 Attempting to install $name from $repo_url"

    # Clone strategies array
    local clone_strategies=(
        # Strategy 1: Direct HTTPS clone (most common)
        "git clone --depth 1 -b $branch $repo_url $CUSTOM_NODES_DIR/$name"
        
        # Strategy 2: Shallow clone with no user interaction
        "GIT_TERMINAL_PROMPT=0 git clone --depth 1 -b $branch $repo_url $CUSTOM_NODES_DIR/$name"
        
        # Strategy 3: Convert to public HTTPS URL
        "git clone --depth 1 -b $branch $(echo $repo_url | sed -e 's/git@github\.com:/https:\/\/github.com\//' -e 's/\.git$//')"
        
        # Strategy 4: Raw HTTP clone (last resort)
        "git clone --depth 1 -b $branch $(echo $repo_url | sed 's/https:\/\//http:\/\//')"
    )

    # Try each clone strategy
    for strategy in "${clone_strategies[@]}"; do
        log "🔄 Trying clone strategy: $strategy"
        
        # Suppress all output, we'll handle logging
        if timeout 300 bash -c "$strategy" >/dev/null 2>&1; then
            clone_success=true
            break
        fi
    done

    # Check if clone was successful
    if [ "$clone_success" = false ]; then
        error_exit "Failed to clone $name from $repo_url using all available strategies"
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

    # Verify git and pip are available
    command -v git >/dev/null 2>&1 || error_exit "Git is not installed"
    command -v pip >/dev/null 2>&1 || error_exit "Pip is not installed"

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
