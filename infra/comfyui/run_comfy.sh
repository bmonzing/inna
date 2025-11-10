#!/usr/bin/env bash
set -euo pipefail

# ComfyUI Launch Script for M3 Pro MacBook Pro
# Optimized for Apple Silicon with MPS acceleration

# Change to ComfyUI directory
cd /Users/287096/comfyui

# Activate virtual environment if it exists, otherwise use system Python
if [ -d ".venv" ]; then
    echo "Activating virtual environment..."
    source .venv/bin/activate
else
    echo "Using system Python (no virtual environment found)"
fi

# M3 Pro Apple Silicon optimizations
echo "Setting up M3 Pro optimizations..."

# MPS: gracefully fall back to CPU for unsupported operations
export PYTORCH_ENABLE_MPS_FALLBACK=1

# Optional: helps reduce OOM by letting memory grow as needed on MPS
export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0

# Disable telemetry for privacy
export HF_HUB_DISABLE_TELEMETRY=1
export DO_NOT_TRACK=1

# Additional MPS optimizations for stability
export MPS_DEVICE=0

echo "Starting ComfyUI with M3 Pro optimizations..."
echo "Server will be available at: http://127.0.0.1:8188"
echo "Press Ctrl+C to stop the server"
echo ""

# Launch ComfyUI with optimized settings
# Use explicit path to ensure we get the venv's python
exec "$PWD/.venv/bin/python3" main.py --listen 127.0.0.1 --port 8188


