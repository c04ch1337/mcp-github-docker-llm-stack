#!/usr/bin/env bash
set -euo pipefail
WITH_NVIDIA="${ENABLE_NVIDIA_RUNTIME:-false}"
if [[ "${1:-}" == "--with-nvidia" ]]; then WITH_NVIDIA=true; fi
echo "[*] Updating apt index..."; sudo apt-get update -y
echo "[*] Installing base prerequisites..."; sudo apt-get install -y ca-certificates curl gnupg lsb-release
echo "[*] Configuring Docker apt repo & key..."
sudo install -m 0755 -d //etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
echo "[*] Installing Docker Engine + Compose..."
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$USER" || true
docker --version
docker compose version
if [[ "${WITH_NVIDIA}" == "true" ]]; then
  echo "[*] Enabling NVIDIA Container Toolkit (stable list to avoid 404s)..."
  sudo install -m 0755 -d /usr/share/keyrings
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
  curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list |     sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#' |     sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install -y nvidia-container-toolkit
  sudo nvidia-ctk runtime configure --runtime=docker
  sudo systemctl restart docker
fi
echo "[*] Basic Docker validation..."; docker info >/dev/null && echo "    - docker info: OK"
if [[ "${WITH_NVIDIA}" == "true" ]]; then
  echo "[*] NVIDIA runtime validation..."
  if docker info | awk '/Runtimes:/,/Default Runtime:/' | grep -q nvidia; then echo "    - nvidia runtime: present"; else echo "    - nvidia runtime: NOT detected" >&2; fi
  if command -v nvidia-smi >/dev/null 2>&1; then
    echo "    - host driver: nvidia-smi found; running CUDA base container quick check"
    set +e; docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi; rc=$?; set -e
    if [[ $rc -ne 0 ]]; then echo "    - GPU container validation FAILED"; else echo "    - GPU container validation: OK"; fi
  else
    echo "    - host driver not detected (nvidia-smi missing). Install a driver and reboot, then re-run validation."
  fi
fi
echo "[*] Done. Log out/in if 'docker' group is newly applied."
