#!/bin/bash
# setup_extensions.sh - Docker & Vast.ai Safe Extension Installer
# https://github.com/DnsSrinath/vast-scripts

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "📦 Starting ComfyUI extensions installation..."

# Ensure ComfyUI exists
if [ ! -d "/workspace/ComfyUI" ]; then
    log "❌ ERROR: /workspace/ComfyUI not found. Please run setup_comfyui.sh first."
    exit 1
fi

# Setup working directory
EXT_DIR="/workspace/ComfyUI/custom_nodes"
mkdir -p "$EXT_DIR"
cd "$EXT_DIR" || exit 1

# Function to download and extract tar.gz or zip fallback
download_and_extract() {
    local name="$1"
    local tar_url="$2"
    local zip_url="$3"
    local target="${EXT_DIR}/${name}"

    if [ -d "$target" ] && [ -f "$target/__init__.py" ]; then
        log "✅ $name already installed, skipping."
        return
    elif [ -d "$target" ]; then
        log "♻️  Cleaning incomplete $name and retrying..."
        rm -rf "$target"
    fi

    mkdir -p "$target"
    log "🔽 Trying tar.gz for $name..."
    if curl -fsL "$tar_url" | tar -xz -C "$target" --strip-components=1 2>/dev/null; then
        log "✅ $name installed via tar.gz"
    else
        log "⚠️  tar.gz failed. Falling back to .zip for $name..."
        tmp_zip="temp_${name}.zip"
        curl -fsL "$zip_url" -o "$tmp_zip"
        unzip -q "$tmp_zip" -d "$target-temp"
        mv "$target-temp"/* "$target"/
        rm -rf "$tmp_zip" "$target-temp"
    fi

    # Validate installation
    if [ -f "$target/__init__.py" ]; then
        log "✅ $name ready to use"
    else
        log "⚠️  $name installed but missing __init__.py"
    fi

    # Install pip requirements
    if [ -f "$target/requirements.txt" ]; then
        log "📦 Installing Python packages for $name..."
        pip install --no-cache-dir -r "$target/requirements.txt"
    fi
}

log "🔧 Installing core extensions..."

download_and_extract "ComfyUI-Manager" \
    "https://github.com/ltdrdata/ComfyUI-Manager/archive/refs/heads/main.tar.gz" \
    "https://github.com/ltdrdata/ComfyUI-Manager/archive/refs/heads/main.zip"

download_and_extract "ComfyUI-Impact-Pack" \
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack/archive/refs/heads/main.tar.gz" \
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack/archive/refs/heads/main.zip"

download_and_extract "ComfyUI-WAN-Suite" \
    "https://github.com/WASasquatch/ComfyUI-WAN-Suite/archive/refs/heads/main.tar.gz" \
    "https://github.com/WASasquatch/ComfyUI-WAN-Suite/archive/refs/heads/main.zip"

log "✨ Installing additional extensions..."

download_and_extract "comfyui-nodes-base" \
    "https://github.com/Acly/comfyui-nodes-base/archive/refs/heads/main.tar.gz" \
    "https://github.com/Acly/comfyui-nodes-base/archive/refs/heads/main.zip"

download_and_extract "ComfyUI_IPAdapter_plus" \
    "https://github.com/cubiq/ComfyUI_IPAdapter_plus/archive/refs/heads/main.tar.gz" \
    "https://github.com/cubiq/ComfyUI_IPAdapter_plus/archive/refs/heads/main.zip"

download_and_extract "comfyui-nodes-rgthree" \
    "https://github.com/rgthree/comfyui-nodes-rgthree/archive/refs/heads/main.tar.gz" \
    "https://github.com/rgthree/comfyui-nodes-rgthree/archive/refs/heads/main.zip"

log "📚 Installing common dependencies for all extensions..."
pip install --no-cache-dir opencv-python onnxruntime onnx transformers accelerate safetensors
pip install --no-cache-dir insightface timm fairscale prettytable ultralytics

log "✅ All extensions installed!"
log "📂 Installed extensions list:"
for dir in */; do
    if [ -f "$dir/__init__.py" ]; then
        log "  - ${dir%/} (✅ ready)"
    else
        log "  - ${dir%/} (⚠️ incomplete)"
    fi
done

log "🚀 Setup complete! You can now start ComfyUI."
log "▶ Run: cd /workspace && ./start_comfyui.sh"
log "🌐 Access ComfyUI at: http://$(hostname -I | awk '{print $1}'):8188"
