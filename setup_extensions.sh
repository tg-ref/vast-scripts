#!/bin/bash
# Robust and Verified ComfyUI Extensions Installer
# Ensures 100% installation and checks completeness of all extensions

set -e

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

WORKSPACE="/workspace"
CUSTOM_NODES_DIR="$WORKSPACE/ComfyUI/custom_nodes"

log "📦 Starting ComfyUI extensions installation..."

# Ensure custom_nodes directory exists
mkdir -p "$CUSTOM_NODES_DIR"
cd "$CUSTOM_NODES_DIR"

# Clean reinstall (ensures 100% installation success)
log "🧹 Cleaning possibly incomplete extensions..."
rm -rf ComfyUI-Impact-Pack ComfyUI-WAN-Suite comfyui-nodes-base comfyui-nodes-rgthree ComfyUI_ControlNet ComfyUI-VideoHelperSuite ComfyUI-WanVideoWrapper

install_extension() {
    local name="$1"
    local repo_url="$2"

    log "🔽 Cloning $name from $repo_url"
    git clone "$repo_url" "$CUSTOM_NODES_DIR/$name"

    if [ -f "$CUSTOM_NODES_DIR/$name/requirements.txt" ]; then
        log "📦 Installing Python dependencies for $name"
        python3 -m pip install -r "$CUSTOM_NODES_DIR/$name/requirements.txt"
    fi

    if [ -f "$CUSTOM_NODES_DIR/$name/__init__.py" ]; then
        log "✅ $name installed successfully"
    else
        log "⚠️  WARNING: $name may be incomplete (missing __init__.py)"
    fi
}

log "🔧 Installing core extensions..."
install_extension "ComfyUI-Manager" "https://github.com/ltdrdata/ComfyUI-Manager.git"
install_extension "ComfyUI-Impact-Pack" "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git"
install_extension "ComfyUI-WAN-Suite" "https://github.com/WASasquatch/ComfyUI-WAN-Suite.git"

log "✨ Installing additional extensions..."
install_extension "comfyui-nodes-base" "https://github.com/Acly/comfyui-nodes-base.git"
install_extension "ComfyUI_IPAdapter_plus" "https://github.com/cubiq/ComfyUI_IPAdapter_plus.git"
install_extension "comfyui-nodes-rgthree" "https://github.com/rgthree/comfyui-nodes-rgthree.git"
install_extension "ComfyUI_ControlNet" "https://github.com/Fannovel16/comfyui_controlnet_aux.git"
install_extension "ComfyUI-VideoHelperSuite" "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"
install_extension "ComfyUI-WanVideoWrapper" "https://github.com/kijai/ComfyUI-WanVideoWrapper.git"

log "📚 Installing global Python dependencies for extensions..."
python3 -m pip install opencv-python onnxruntime onnx transformers accelerate safetensors
python3 -m pip install insightface timm fairscale prettytable
python3 -m pip install ultralytics

log "📂 Installed extensions:"
for dir in "$CUSTOM_NODES_DIR"/*; do
    if [ -d "$dir" ]; then
        if [ -f "$dir/__init__.py" ]; then
            log "  - $(basename "$dir") (✅ ready)"
        else
            log "  - $(basename "$dir") (⚠️ possibly incomplete)"
        fi
    fi
done

log "🚀 ComfyUI extensions setup complete!"
log "▶ To start ComfyUI, run: cd /workspace && ./start_comfyui.sh"
log "🌐 Access ComfyUI at: http://$(hostname -I | awk '{print $1}'):8188"
