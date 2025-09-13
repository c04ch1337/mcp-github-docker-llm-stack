
#!/usr/bin/env bash
set -euo pipefail

echo "[*] Updating apt index..."
sudo apt-get update -y

echo "[*] Installing prerequisites..."
sudo apt-get install -y ca-certificates curl gnupg lsb-release

echo "[*] Adding Docker's official GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

UBUNTU_CODENAME=$(lsb_release -cs)
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "[*] Installing Docker Engine + Compose..."
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "[*] Adding current user to docker group..."
sudo usermod -aG docker "$USER" || true

if [[ "${ENABLE_NVIDIA_RUNTIME:-false}" == "true" ]]; then
  echo "[*] Installing NVIDIA Container Toolkit..."
  distribution=$(. /etc/os-release;echo $ID$VERSION_ID)     && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg     && curl -fsSL https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list |        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' |        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
  sudo apt-get update -y
  sudo apt-get install -y nvidia-container-toolkit
  sudo nvidia-ctk runtime configure --runtime=docker
  sudo systemctl restart docker
fi

echo "[*] Docker installed. Log out/in to refresh group membership if needed."
docker --version || true
docker compose version || true
