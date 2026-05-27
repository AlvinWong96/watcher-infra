# Watcher Infra

Docker Compose orchestration for the **Watcher** news & stocks dashboard.

## Services
| Service | Image | Purpose |
|---|---|---|
| `watcher` | PHP 8.2 + Apache (custom) | Web app — news, stocks, chat UI |
| `predictor` | Python 3.11 + Flask | ML stock price predictor |
| `ollama` | `ollama/ollama:latest` | Local LLM for AI news summaries |
| `ollama-init` | `ollama/ollama:latest` | One-shot model downloader |

## Requirements
- Docker + Docker Compose
- 4 GB free disk (for the LLM model)
- 4 GB RAM minimum (8 GB recommended)

## Quick Start

```bash
git clone https://github.com/AlvinWong96/watcher-infra.git
cd watcher-infra
mkdir -p src/html src/predictor
git clone https://github.com/AlvinWong96/watcher.git src/html/watcher
git clone https://github.com/AlvinWong96/watcher-predictor.git src/predictor
docker compose up -d
```

Open **http://localhost:8080/watcher/** after ~2 minutes (model download time).

## Configuration

Edit environment variables in `docker-compose.yml`:

| Variable | Default | Description |
|---|---|---|
| `AI_PROVIDER` | `ollama` | `ollama` = local, `groq` = cloud, `` = disabled |
| `OLLAMA_MODEL` | `llama3.2:3b` | Any model available in Ollama |
| `GROQ_API_KEY` | *(empty)* | Required only when `AI_PROVIDER=groq` |

## Related Repos
- [watcher](https://github.com/AlvinWong96/watcher) — PHP/JS web application
- [watcher-predictor](https://github.com/AlvinWong96/watcher-predictor) — Python ML microservice
