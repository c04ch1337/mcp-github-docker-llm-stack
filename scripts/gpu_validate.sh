#!/usr/bin/env bash
set -euo pipefail
echo "[*] docker runtime check"
docker info | sed -n '/Runtimes:/,/Default Runtime:/p' || true
if command -v nvidia-smi >/dev/null 2>&1; then
  echo "[*] nvidia-smi (host)"; nvidia-smi || true
  echo "[*] CUDA base image nvidia-smi (container)"
  docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi || true
else
  echo "[!] nvidia-smi not found on host. Install NVIDIA driver and reboot."
fi
