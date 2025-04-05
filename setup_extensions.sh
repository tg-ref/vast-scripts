#!/bin/bash
# 🚀 Advanced ComfyUI Extensions Installer
# Robust installation with comprehensive download strategies
# Updated with WAN 2.1 Image to Video support

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
MODEL_DIR="$COMFYUI_DIR/models"

# Create directories
mkdir -p "$CUSTOM_NODES_DIR"
mkdir -p "$MODEL_DIR/checkpoints"
mkdir -p "$MODEL_DIR/clip"
mkdir -p "$MODEL_DIR/clip_vision"
mkdir -p "$MODEL_DIR/vae"
mkdir -p /tmp/extensions

# Cleanup function
cleanup() {
    log "🧹 Cleaning up previous extensions..."
    rm -rf /tmp/extensions/*
}

# Advanced download diagnostics
debug_download() {
    local name="$1"
    local download_url="$2"
    local output_file="/tmp/extensions/${name}.zip"

    log "🕵️ Debugging download for $name"
    
    # Verbose curl download
    log "📡 Downloading from: $download_url"
    
    # Detailed curl with verbose output
    curl_output=$(curl -v -L -f -o "$output_file" "$download_url" 2>&1)
    curl_exit_code=$?

    # Log curl details
    log "🔍 Curl verbose output:"
    echo "$curl_output"

    # Check download result
    if [ $curl_exit_code -ne 0 ]; then
        log "❌ Curl download failed with exit code $curl_exit_code"
        return 1
    fi

    # Check file existence and size
    if [ ! -f "$output_file" ]; then
        log "❌ No file was downloaded"
        return 1
    fi

    local file_size=$(stat -c%s "$output_file")
    if [ $file_size -eq 0 ]; then
        log "❌ Downloaded file is empty"
        return 1
    fi

    # Try to determine file type
    file_type=$(file -b "$output_file")
    log "📄 File type: $file_type"

    return 0
}

# Advanced manual download function
advanced_download_extension() {
    local name="$1"
    local repo_url="$2"
    local branch="${3:-main}"
    local download_urls=(
        # Primary download URL formats
        "https://github.com/$(echo "$repo_url" | cut -d'/' -f4-5 | sed 's/\.git$//')/archive/refs/heads/${branch}.zip"
        "https://codeload.github.com/$(echo "$repo_url" | cut -d'/' -f4-5 | sed 's/\.git$//')/zip/refs/heads/${branch}"
        "https://github.com/$(echo "$repo_url" | cut -d'/' -f4-5 | sed 's/\.git$//')/zipball/${branch}"
    )

    log "🚨 Attempting advanced download for $name"

    # Try multiple download methods
    for download_url in "${download_urls[@]}"; do
        # Clean previous download attempts
        rm -f "/tmp/extensions/${name}.zip"
        
        # Attempt download with diagnostics
        if debug_download "$name" "$download_url"; then
            # Try multiple extraction methods
            local extraction_methods=(
                "unzip -q /tmp/extensions/${name}.zip -d /tmp/extensions"
                "tar -xf /tmp/extensions/${name}.zip -C /tmp/extensions"
            )

            for method in "${extraction_methods[@]}"; do
                log "🔓 Trying extraction: $method"
                
                # Attempt extraction
                if $method; then
                    # Find and move extracted directory
                    extracted_dir=$(find "/tmp/extensions" -maxdepth 1 -type d -name "*${name}*" | head -n 1)
                    if [ -n "$extracted_dir" ]; then
                        mv "$extracted_dir" "$CUSTOM_NODES_DIR/$name"
                        log "✅ Successfully downloaded and extracted $name"
                        return 0
                    fi
                else
                    log "❌ Extraction failed with method: $method"
                fi
            done
        fi
    done

    error_exit "Failed to download $name using all available methods"
}

# Extension installation function
install_extension() {
    local name="$1"
    local repo_url="$2"
    local branch="${3:-main}"
    local clone_success=false

    log "🔽 Attempting to install $name from $repo_url"

    # Skip if already installed
    if [ -d "$CUSTOM_NODES_DIR/$name" ]; then
        log "⏩ $name already installed, skipping"
        return 0
    fi

    # Clone strategies array
    local clone_strategies=(
        # Direct HTTPS clone
        "git clone --depth 1 -b $branch $repo_url $CUSTOM_NODES_DIR/$name"
        
        # No terminal prompt strategy
        "GIT_TERMINAL_PROMPT=0 git clone --depth 1 -b $branch $repo_url $CUSTOM_NODES_DIR/$name"
        
        # Convert SSH to HTTPS
        "git clone --depth 1 -b $branch $(echo $repo_url | sed -e 's/git@github\.com:/https:\/\/github.com\//' -e 's/\.git$//')"
    )

    # Try each clone strategy
    for strategy in "${clone_strategies[@]}"; do
        log "🔄 Trying clone strategy: $strategy"
        
        if timeout 300 bash -c "$strategy" >/dev/null 2>&1; then
            clone_success=true
            break
        fi
    done

    # If all clone strategies fail, attempt advanced download
    if [ "$clone_success" = false ]; then
        log "❌ Clone strategies failed. Attempting advanced download..."
        advanced_download_extension "$name" "$repo_url" "$branch"
    fi

    # Install Python dependencies
    if [ -f "$CUSTOM_NODES_DIR/$name/requirements.txt" ]; then
        log "📦 Installing Python dependencies for $name"
        timeout 600 pip install --no-cache-dir -r "$CUSTOM_NODES_DIR/$name/requirements.txt" || {
            log "⚠️ Warning: Some dependencies for $name failed to install"
        }
    fi

    # Verify installation
    if [ ! -f "$CUSTOM_NODES_DIR/$name/__init__.py" ] && [ ! -f "$CUSTOM_NODES_DIR/$name"/*/__init__.py ]; then
        log "⚠️ $name may be incomplete (missing __init__.py)"
    else
        log "✅ $name installed successfully"
    fi
}

# Function to download WAN 2.1 Image to Video models
download_wan_i2v_models() {
    log "📥 Downloading WAN 2.1 Image to Video models..."
    
    # Create necessary directories
    mkdir -p "$MODEL_DIR/checkpoints"
    mkdir -p "$MODEL_DIR/clip"
    mkdir -p "$MODEL_DIR/clip_vision"
    mkdir -p "$MODEL_DIR/vae"
    
    # Download main model
    if [ ! -f "$MODEL_DIR/checkpoints/wan2.1-i2v-14b-480p-Q4_K_S.gguf" ]; then
        log "⬇️ Downloading WAN Image to Video model..."
        wget --progress=bar:force:noscroll -c \
             https://huggingface.co/Kijai/WanImage2Video/resolve/main/wan2.1-i2v-14b-480p-Q4_K_S.gguf \
             -O "$MODEL_DIR/checkpoints/wan2.1-i2v-14b-480p-Q4_K_S.gguf" || {
            log "⚠️ Warning: Failed to download WAN Image to Video model"
            return 1
        }
        log "✅ WAN Image to Video model downloaded"
    else
        log "⏩ WAN Image to Video model already exists, skipping"
    fi
    
    # Download VAE
    if [ ! -f "$MODEL_DIR/vae/wan_2.1_vae_Comfy-Org.safetensors" ]; then
        log "⬇️ Downloading WAN VAE..."
        wget --progress=bar:force:noscroll -c \
             https://huggingface.co/waifu-diffusion/WAN/resolve/main/wan_2.1_vae_Comfy-Org.safetensors \
             -O "$MODEL_DIR/vae/wan_2.1_vae_Comfy-Org.safetensors" || {
            log "⚠️ Warning: Failed to download WAN VAE"
            return 1
        }
        log "✅ WAN VAE downloaded"
    else
        log "⏩ WAN VAE already exists, skipping"
    fi
    
   # Download CLIP model
    if [ ! -f "$MODEL_DIR/clip/umt5_xxl_fp8_e4m3fn_scaled.safetensors" ]; then
        log "⬇️ Downloading WAN CLIP model..."
        wget --progress=bar:force:noscroll -c \
             https://huggingface.co/waifu-diffusion/WAN/resolve/main/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
             -O "$MODEL_DIR/clip/umt5_xxl_fp8_e4m3fn_scaled.safetensors" || {
            log "⚠️ Warning: Failed to download WAN CLIP model"
            return 1
        }
        log "✅ WAN CLIP model downloaded"
    else
        log "⏩ WAN CLIP model already exists, skipping"
    fi
    
    # Download CLIP Vision model
    if [ ! -f "$MODEL_DIR/clip_vision/clip_vision_h_Comfy-Org.safetensors" ]; then
        log "⬇️ Downloading CLIP Vision model..."
        wget --progress=bar:force:noscroll -c \
             https://huggingface.co/h94/IP-Adapter/resolve/main/models/clip_vision_h.safetensors \
             -O "$MODEL_DIR/clip_vision/clip_vision_h_Comfy-Org.safetensors" || {
            log "⚠️ Warning: Failed to download CLIP Vision model"
            return 1
        }
        log "✅ CLIP Vision model downloaded"
    else
        log "⏩ CLIP Vision model already exists, skipping"
    fi
    
    log "✅ All WAN 2.1 Image to Video models downloaded successfully"
    return 0
}

# Create run script for WAN optimized settings
create_wan_run_script() {
    log "📝 Creating optimized WAN startup script..."
    
    cat > "$WORKSPACE/run_wan_i2v.sh" << 'EOL'
#!/bin/bash
# Optimized startup script for WAN 2.1 Image to Video

cd /workspace/ComfyUI
python main.py --listen --port 8188 --enable-insecure-extension-install --force-fp16
EOL

    chmod +x "$WORKSPACE/run_wan_i2v.sh"
    log "✅ Created optimized WAN startup script at $WORKSPACE/run_wan_i2v.sh"
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
    command -v tar >/dev/null 2>&1 || error_exit "Tar is not installed"
    command -v file >/dev/null 2>&1 || error_exit "File utility is not installed"
    command -v wget >/dev/null 2>&1 || error_exit "Wget is not installed"

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
        
        # Add WAN 2.1 Image to Video specific extensions
        "ComfyUI-WanImage2Video-Extension:https://github.com/kijai/ComfyUI-WanImage2Video-Extension.git"
        "ComfyUI-GGUF:https://github.com/city96/ComfyUI-GGUF.git"
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
        
        # Add dependencies specific to WAN 2.1 Image to Video
        "torch"
        "torchvision"
        "einops"
        "numpy"
        "pillow"
    )

    for dep in "${global_deps[@]}"; do
        pip install --no-cache-dir "$dep" || {
            log "⚠️ Warning: Failed to install $dep"
        }
    done

    # Download WAN 2.1 Image to Video models
    download_wan_i2v_models
    
    # Create optimized run script
    create_wan_run_script

    # Final summary
    log "📂 Installed Extensions:"
    for dir in "$CUSTOM_NODES_DIR"/*; do
        if [ -d "$dir" ]; then
            if [ -f "$dir/__init__.py" ] || [ -f "$dir"/*/__init__.py ]; then
                echo "  ✅ $(basename "$dir")"
            else
                echo "  ⚠️ $(basename "$dir") (possibly incomplete)"
            fi
        fi
    done

    log "🎬 WAN 2.1 Image to Video Models:"
    if [ -f "$MODEL_DIR/checkpoints/wan2.1-i2v-14b-480p-Q4_K_S.gguf" ]; then
        echo "  ✅ Model: wan2.1-i2v-14b-480p-Q4_K_S.gguf"
    else
        echo "  ❌ Model: wan2.1-i2v-14b-480p-Q4_K_S.gguf (missing)"
    fi
    
    if [ -f "$MODEL_DIR/vae/wan_2.1_vae_Comfy-Org.safetensors" ]; then
        echo "  ✅ VAE: wan_2.1_vae_Comfy-Org.safetensors"
    else
        echo "  ❌ VAE: wan_2.1_vae_Comfy-Org.safetensors (missing)"
    fi
    
    if [ -f "$MODEL_DIR/clip/umt5_xxl_fp8_e4m3fn_scaled.safetensors" ]; then
        echo "  ✅ CLIP: umt5_xxl_fp8_e4m3fn_scaled.safetensors"
    else
        echo "  ❌ CLIP: umt5_xxl_fp8_e4m3fn_scaled.safetensors (missing)"
    fi
    
    if [ -f "$MODEL_DIR/clip_vision/clip_vision_h_Comfy-Org.safetensors" ]; then
        echo "  ✅ CLIP Vision: clip_vision_h_Comfy-Org.safetensors"
    else
        echo "  ❌ CLIP Vision: clip_vision_h_Comfy-Org.safetensors (missing)"
    fi

    log "🚀 ComfyUI extensions and WAN 2.1 Image to Video installation complete!"
    log "▶ Ready to start ComfyUI with: $WORKSPACE/run_wan_i2v.sh"
}

# Run the main function
main
