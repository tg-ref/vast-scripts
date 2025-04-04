#!/bin/bash
# ComfyUI Extensions Setup Script - Docker Safe & Reliable
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

# Prepare target directory
EXT_DIR="/workspace/ComfyUI/custom_nodes"
mkdir -p "$EXT_DIR"
cd "$EXT_DIR" || exit 1

# Function to download tarball and extract
download_and_extract() {
    local name="$1"
    local tar_url="$2"
    local target="${EXT_DIR}/${name}"

    if [ -d "$target" ]; then
        log "✅ $name already exists, skipping."
        return
    fi

    log "🔽 Downloading $name from tarball..."
    mkdir -p "$target"
    curl -L "$tar_url" | tar -xz -C "$target" --strip-components=1

    if [ -f "${target}/__init__.py" ]; then
        log "✅ $name installed successfully"
    else
        log "⚠️  WARNING: $name installed but missing __init__.py"
    fi

    if [ -f "${target}/requirements.txt" ]; then
        log "📦 Installing pip requirements for $name..."
        pip install --no-cache-dir -r "${target}/requirements.txt"
    fi
}

log "🔧 Installing core extensions..."

download_and_extract "ComfyUI-Manager" "https://github.com/ltdrdata/ComfyUI-Manager/archive/refs/heads/main.tar.gz"
download_and_extract "ComfyUI-Impact-Pack" "https://github.com/ltdrdata/ComfyUI-Impact-Pack/archive/refs/heads/main.tar.gz"
download_and_extract "ComfyUI-WAN-Suite" "https://github.com/WASasquatch/ComfyUI-WAN-Suite/archive/refs/heads/main.tar.gz"

log "✨ Installing additional extensions..."

download_and_extract "comfyui-nodes-base" "https://github.com/Acly/comfyui-nodes-base/archive/refs/heads/main.tar.gz"
download_and_extract "ComfyUI_IPAdapter_plus" "https://github.com/cubiq/ComfyUI_IPAdapter_plus/archive/refs/heads/main.tar.gz"
download_and_extract "comfyui-nodes-rgthree" "https://github.com/rgthree/comfyui-nodes-rgthree/archive/refs/heads/main.tar.gz"

log "📚 Installing global Python dependencies for extensions..."
pip install --no-cache-dir opencv-python onnxruntime onnx transformers accelerate safetensors
pip install --no-cache-dir insightface timm fairscale prettytable ultralytics

log "✅ All extensions installed successfully!"
log "📂 Installed extensions:"
for dir in */; do
    if [ -f "$dir/__init__.py" ]; then
        log "  - ${dir%/} (ready)"
    else
        log "  - ${dir%/} (⚠️ possibly incomplete)"
    fi
done

log "🚀 ComfyUI extensions setup complete!"
log "▶ To start ComfyUI, run: cd /workspace && ./start_comfyui.sh"
log "🌐 Access ComfyUI at: http://$(hostname -I | awk '{print $1}'):8188"
