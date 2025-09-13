
#!/usr/bin/env bash
set -euo pipefail

MODELS_CSV="${OLLAMA_MODELS:-}"
if [[ -z "$MODELS_CSV" ]]; then
  echo "[*] No OLLAMA_MODELS specified. Skip pre-pull."
  exit 0
fi

IFS=',' read -ra MODELS <<< "$MODELS_CSV"
for m in "${MODELS[@]}"; do
  echo "[*] Pulling model: $m"
  ollama pull "$m" || echo "[!] Failed to pull $m (will retry later)"
done
