
# mcp-github-docker-llm-stack

A production-ready starter to run the **GitHub MCP Server** behind the **Docker MCP Gateway**, plus **local LLM inference** with **Ollama** (and optional **llama.cpp**) on Ubuntu 24.04. Built for a home lab with a multi-GPU rig.

> ✅ GitHub MCP + Gateway + LLMs (local)  
> 🔒 Security-conscious, .env driven  
> 🐧 Host: Ubuntu 24.04; GPUs optional (recommended)

## Diagram

```
[ Claude / VS Code MCP client ]
             |
       (HTTP / WS)
             |
     [ MCP Gateway ]
         |      \
         |       \ (future) MCP-LLM bridge
         v
 [ GitHub MCP Srv ]        [ Ollama / llama.cpp ]
         |                           |
     GitHub API                 Local inference
```

## Quick start

1) **Install Docker & (optional) NVIDIA toolkit**
```bash
cd mcp-github-docker-llm-stack
ENABLE_NVIDIA_RUNTIME=true bash ./scripts/install_docker_ubuntu24.sh
# log out/in if needed so your user is in the docker group
```

2) **Configure environment**
```bash
cp .env.example .env
# Set GITHUB_MCP_TOKEN (fine-scoped PAT; start read-only)
# Set OLLAMA_MODELS (e.g., llama3.1:8b,mistral:7b-instruct)
```

3) **Launch core stack**
```bash
bash ./scripts/bootstrap_gateway.sh
# Gateway:   http://localhost:8080
# GitHub MCP: http://<LAN-IP>:7000
# Ollama:    http://<LAN-IP>:11434
```

4) **(Optional) Start llama.cpp server**
```bash
docker compose --profile llamacpp up -d llama-cpp
# Provide a GGUF via ./models and pass a --model arg in compose if desired
```

## Using the LLMs

- **Ollama API**: OpenAI-like HTTP endpoints at `/api/generate` and `/api/chat`.  
  Test quickly:
  ```bash
  curl http://localhost:11434/api/tags
  curl -s http://localhost:11434/api/generate -d '{"model":"mistral:7b-instruct","prompt":"Say hello"}'
  ```

- **llama.cpp server**: Basic HTTP server on `${LLAMACPP_PORT}` (default 8081). Mount a model to `/models` and add `--model /models/your.gguf` in the command if needed.

## MCP + LLMs (how to bridge)

The gateway is already wired to `github`. To expose LLMs to MCP-aware clients, run an **MCP server** that talks to Ollama/OpenAI-compatible endpoints, then register it in `mcp/config/gateway.yaml`:
```yaml
gateway:
  servers:
    - name: github
      transport: { http: { url: "http://github-mcp:3000" } }
    # - name: llm
    #   transport: { http: { url: "http://llm-mcp:3000" } }
clients:
  - name: vscode
    allow: [github] # add 'llm' once you run it
```

This keeps inference local while giving your MCP client a standard tool interface.

## Home-lab networking

- Reserve the host IP (DHCP reservation) and set `MCP_LAN_HOST` in `.env`.
- Add a local DNS record like `mcp.local.lan` → `MCP_GATEWAY_PORT`.
- For remote access, prefer Tailscale/Zerotier over raw port-forwarding. If you must expose, put TLS + auth in front (Caddy/Traefik).

## Security

- Least-privilege PAT for GitHub MCP. Start with read scopes; add write only when needed.
- Keep gateway private; if exposing, require TLS + auth.
- Never commit `.env`.

## Operations

```bash
# Update images
docker compose pull && docker compose up -d

# Logs
docker compose logs -f mcp-gateway
docker compose logs -f github-mcp
docker compose logs -f ollama
```

## License

MIT — see LICENSE.
