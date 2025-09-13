
#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f ".env" ]]; then
  echo "[*] Creating .env from template .env.example"
  cp .env.example .env
  echo "[*] Edit .env to set your GITHUB_MCP_TOKEN and OLLAMA_MODELS before starting."
fi

echo "[*] Bringing up core services (gateway + github-mcp + ollama)..."
docker compose up -d mcp-gateway github-mcp ollama

echo "[*] Waiting a few seconds for health checks..."
sleep 5
docker compose ps

echo
echo "== Endpoints =="
echo "Gateway:        http://localhost:${MCP_GATEWAY_PORT:-8080}"
echo "GitHub MCP:     http://${MCP_LAN_HOST:-127.0.0.1}:${GITHUB_MCP_PORT:-7000} (host-mapped)"
echo "Ollama API:     http://${MCP_LAN_HOST:-127.0.0.1}:${OLLAMA_PORT:-11434}"
echo
echo "Tip: enable llama.cpp service with: docker compose --profile llamacpp up -d llama-cpp"
