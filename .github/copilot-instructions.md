# Watcher Infra — Copilot Context

## Development Environment
All development happens at `/home/alvinwong/project/docker/` on the local machine.
Component source repos are checked out inside this folder:
- `src/html/watcher/` → [AlvinWong96/watcher](https://github.com/AlvinWong96/watcher)
- `src/predictor/`    → [AlvinWong96/watcher-predictor](https://github.com/AlvinWong96/watcher-predictor)

## Always Check `.docs/` First
Each component repo contains a `.docs/` folder with detailed architecture and behaviour notes.
**Before making changes to any component, read its `.docs/` files:**
- `src/html/watcher/.docs/` — watcher web app docs (news.php SSE, news.js pagination, architecture)
- `src/predictor/.docs/`    — predictor ML service docs (endpoints, models)

**After making changes, update the relevant `.docs/` files to reflect the new behaviour.**
This keeps the docs accurate for future sessions and prevents stale context from causing mistakes.

## Overview
Docker Compose orchestration for the Watcher dashboard app.
4 services: `watcher` (PHP/Apache), `predictor` (Python/Flask), `ollama` (LLM), `ollama-init` (one-shot model pull).

## Directory Layout
```
docker/
├── Dockerfile            # PHP 8.2 + Apache image for watcher service
├── docker-compose.yml    # Orchestrates all 4 services
└── src/                  # NOT in this repo — clone separately
    ├── html/watcher/     # → clone AlvinWong96/watcher here
    └── predictor/        # → clone AlvinWong96/watcher-predictor here
```

## Services

### watcher (PHP 8.2 + Apache)
- Image: built from `Dockerfile`
- Port: `8080:80`
- Serves: `http://localhost:8080/watcher/`
- Key env vars:
  - `AI_PROVIDER=ollama` — set to `groq` for cloud, empty to disable AI
  - `OLLAMA_HOST=http://ollama:11434`
  - `OLLAMA_MODEL=llama3.2:3b`
  - `PREDICTOR_HOST=http://predictor:5000`
  - `GROQ_API_KEY=` — fill in for Groq cloud LLM

### predictor (Python 3.11 + Flask + gunicorn)
- Port: internal only (accessed via `http://predictor:5000`)
- Endpoints: `/health`, `/predict`, `/indicators`

### ollama
- Image: `ollama/ollama:latest` (0.24.0 as of May 2026)
- **CPU-only mode** — `CUDA_VISIBLE_DEVICES=` (empty) forces CPU, avoids SIGSEGV on GTX 960 (Compute 5.2)
- Key env vars:
  - `OLLAMA_NO_MMAP=1` — prevents memory-map issues in Docker
  - `OLLAMA_NUM_PARALLEL=1` — one request at a time on CPU
  - `CUDA_VISIBLE_DEVICES=` — CRITICAL: keeps GPU disabled
- CPU backend: `libggml-cpu-haswell.so` (AVX2, ~15s per article on WSL2 5.8GB RAM)
- Context window: 4096 tokens (default for latest image)

### ollama-init
- One-shot service (`restart: no`) that pulls `llama3.2:3b` on first run
- Waits for `ollama` to be healthy before pulling

## Important Decisions & History
- **Why CPU-only?** GTX 960 (Compute 5.2) causes SIGSEGV in Ollama's CUDA backend during model load (`cgocall` crash). `CUDA_VISIBLE_DEVICES=` is the fix.
- **Why `latest` not `0.3.14`?** `0.24.0` has a better AVX2 CPU backend (~20% faster) and 4096-token context vs 2048 in 0.3.14.
- **Why `OLLAMA_NUM_PARALLEL=1`?** WSL2 has limited RAM (5.8GB). Multiple parallel requests would OOM.
- **Log rotation**: all services use `json-file` driver with `max-size: 10m, max-file: 3`.
- **Healthcheck intervals**: 300s to avoid log spam.
- **Ollama healthcheck**: uses `ollama list` (no curl in the image).

## Setup on a New Machine
```bash
git clone https://github.com/AlvinWong96/watcher-infra.git
cd watcher-infra
mkdir -p src/html src/predictor
git clone https://github.com/AlvinWong96/watcher.git src/html/watcher
git clone https://github.com/AlvinWong96/watcher-predictor.git src/predictor
docker compose up -d
```
Wait ~2 min for `ollama-init` to pull the model, then open `http://localhost:8080/watcher/`.

## Common Commands
```bash
docker compose up -d                          # start all services
docker compose up -d ollama                   # restart ollama only
docker exec watcher-app rm -rf /tmp/watcher_cache  # clear news cache
docker logs watcher-ollama --tail 20          # check Ollama logs
docker logs watcher-app --tail 20             # check PHP/Apache logs
```
