#!/bin/bash
# Extensions and tools setup for ComfyUI on Vast.ai

# Log function
log() {
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1"
}

log "Starting ComfyUI extensions setup..."

# Configure git to use https instead of git protocol
git config --global url."https://".insteadOf git://
# Prevent git from asking for credentials
export GIT_TERMINAL_PROMPT=0

# Check if ComfyUI is installed
if [ ! -d "/workspace/ComfyUI" ]; then
  log "ERROR: ComfyUI directory not found. Please run setup_comfyui.sh first."
  exit 1
fi

# Create custom_nodes directory if it doesn't exist
mkdir -p /workspace/ComfyUI/custom_nodes

# Install WAN 2.1 Suite
log "Installing WAN 2.1 Suite..."
cd /workspace/ComfyUI/custom_nodes
if [ -d "ComfyUI-WAN-Suite" ]; then
  log "WAN 2.1 extension already exists. Updating..."
  cd ComfyUI-WAN-Suite
  git pull
else
  git clone https://github.com/MoonRide303/ComfyUI-WAN-Suite.git
  cd ComfyUI-WAN-Suite
fi
pip install -r requirements.txt

# Download WAN 2.1 model
log "Setting up WAN 2.1 model..."
mkdir -p /workspace/ComfyUI/models/wan_models
cd /workspace/ComfyUI/models/wan_models

# Verify if model exists and is correct size
WAN_MODEL_PATH="/workspace/ComfyUI/models/wan_models/wan_v2_1.pth"
EXPECTED_SIZE="828495429"  # Expected size in bytes for wan_v2_1.pth

if [ -f "$WAN_MODEL_PATH" ]; then
  WAN_MODEL_SIZE=$(stat -c%s "$WAN_MODEL_PATH" 2>/dev/null || echo "0")
  if [ "$WAN_MODEL_SIZE" = "$EXPECTED_SIZE" ]; then
    log "WAN 2.1 model already exists and is verified."
  else
    log "WAN 2.1 model appears to be incomplete or corrupted. Re-downloading..."
    rm -f "$WAN_MODEL_PATH"
    wget --no-verbose --show-progress https://huggingface.co/casmirc/wan_v2_1/resolve/main/wan_v2_1.pth -O "$WAN_MODEL_PATH"
  fi
else
  log "Downloading WAN 2.1 model..."
  wget --no-verbose --show-progress https://huggingface.co/casmirc/wan_v2_1/resolve/main/wan_v2_1.pth -O "$WAN_MODEL_PATH"
fi

# Verify download after attempt
if [ -f "$WAN_MODEL_PATH" ]; then
  WAN_MODEL_SIZE=$(stat -c%s "$WAN_MODEL_PATH" 2>/dev/null || echo "0")
  if [ "$WAN_MODEL_SIZE" = "$EXPECTED_SIZE" ]; then
    log "WAN 2.1 model successfully downloaded and verified."
  else
    log "WARNING: WAN 2.1 model verification failed. Size mismatch: Expected $EXPECTED_SIZE, got $WAN_MODEL_SIZE."
  fi
else
  log "ERROR: Failed to download WAN 2.1 model."
fi

# Create symlinks for model discovery
log "Setting up model symlinks..."
mkdir -p /workspace/ComfyUI/models/checkpoints
ln -sf /workspace/ComfyUI/models/wan_models /workspace/ComfyUI/models/checkpoints/wan_models

# Install ComfyUI Manager (for easy installation of other extensions)
log "Installing ComfyUI Manager..."
cd /workspace/ComfyUI/custom_nodes
if [ -d "ComfyUI-Manager" ]; then
  log "ComfyUI Manager already exists. Updating..."
  cd ComfyUI-Manager
  git pull
else
  git clone https://github.com/ltdrdata/ComfyUI-Manager.git
fi

# Install ControlNet
log "Installing ControlNet extension..."
cd /workspace/ComfyUI/custom_nodes
if [ -d "comfyui_controlnet_aux" ]; then
  log "ControlNet already exists. Updating..."
  cd comfyui_controlnet_aux
  git pull
else
  git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git
  cd comfyui_controlnet_aux
fi
pip install -r requirements.txt

# Install Impact Pack
log "Installing Impact Pack..."
cd /workspace/ComfyUI/custom_nodes
if [ -d "ComfyUI-Impact-Pack" ]; then
  log "Impact Pack already exists. Updating..."
  cd ComfyUI-Impact-Pack
  git pull
else
  git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git
  cd ComfyUI-Impact-Pack
fi
pip install -r requirements.txt
python install.py

# Create a simple test workflow for WAN 2.1
log "Creating test workflow for WAN 2.1..."
mkdir -p /workspace/ComfyUI/test_workflows
cat > /workspace/ComfyUI/test_workflows/wan_test.json << 'EOF'
{
  "last_node_id": 3,
  "last_link_id": 2,
  "nodes": [
    {
      "id": 1,
      "type": "WAN_ImageUpscale",
      "pos": [
        300,
        200
      ],
      "size": {
        "0": 315,
        "1": 122
      },
      "flags": {},
      "order": 1,
      "mode": 0,
      "inputs": [
        {
          "name": "image",
          "type": "IMAGE",
          "link": 1
        },
        {
          "name": "upscale_by",
          "type": "FLOAT",
          "link": null,
          "widget": {
            "name": "upscale_by",
            "config": [
              "FLOAT",
              {
                "default": 2,
                "min": 1,
                "max": 8,
                "step": 0.1
              }
            ]
          },
          "slot_index": 1
        },
        {
          "name": "model_override",
          "type": "MODEL",
          "link": null
        }
      ],
      "outputs": [
        {
          "name": "IMAGE",
          "type": "IMAGE",
          "links": [
            2
          ],
          "slot_index": 0
        }
      ],
      "properties": {
        "Node name for S&R": "WAN_ImageUpscale"
      },
      "widgets_values": [
        2,
        null
      ]
    },
    {
      "id": 2,
      "type": "LoadImage",
      "pos": [
        30,
        200
      ],
      "size": {
        "0": 210,
        "1": 250
      },
      "flags": {},
      "order": 0,
      "mode": 0,
      "outputs": [
        {
          "name": "IMAGE",
          "type": "IMAGE",
          "links": [
            1
          ],
          "slot_index": 0
        },
        {
          "name": "MASK",
          "type": "MASK",
          "links": null
        }
      ],
      "properties": {
        "Node name for S&R": "LoadImage"
      },
      "widgets_values": [
        "example.png",
        "image"
      ]
    },
    {
      "id": 3,
      "type": "PreviewImage",
      "pos": [
        630,
        200
      ],
      "size": {
        "0": 210,
        "1": 246
      },
      "flags": {},
      "order": 2,
      "mode": 0,
      "inputs": [
        {
          "name": "images",
          "type": "IMAGE",
          "link": 2
        }
      ],
      "properties": {
        "Node name for S&R": "PreviewImage"
      }
    }
  ],
  "links": [
    [
      1,
      2,
      0,
      1,
      0,
      "IMAGE"
    ],
    [
      2,
      1,
      0,
      3,
      0,
      "IMAGE"
    ]
  ],
  "groups": [],
  "config": {},
  "extra": {},
  "version": 0.4
}
EOF

# Create sample image for testing
convert -size 256x256 plasma:fractal /workspace/ComfyUI/input/example.png 2>/dev/null || \
log "Note: Could not create test image. 'convert' tool not available."

log "Extensions setup complete!"
log "To start ComfyUI with all extensions, run: cd /workspace/ComfyUI && python main.py --listen 0.0.0.0 --port 8188 --enable-cors-header"
log "A test workflow for WAN 2.1 is available at /workspace/ComfyUI/test_workflows/wan_test.json"
