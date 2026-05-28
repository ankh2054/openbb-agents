# OpenBB + Gemini local Docker setup

Containerized local stack to run OpenBB example agents through Gemini via LiteLLM.

## What this deploys

- `litellm` bridge on `http://127.0.0.1:4000` (OpenAI-compatible API over Gemini)
- `20-financial-prompt-optimizer` on `http://127.0.0.1:8095`
- `30-vanilla-agent-raw-widget-data` on `http://127.0.0.1:8096`
- `31-vanilla-agent-reasoning-steps` on `http://127.0.0.1:8097`
- `32-vanilla-agent-raw-widget-data-citations` on `http://127.0.0.1:8098`
- `34-vanilla-agent-tables` on `http://127.0.0.1:8099`
- `35-vanilla-agent-pdf` on `http://127.0.0.1:8100`
- `36-vanilla-agent-pdf-citations` on `http://127.0.0.1:8101`

All agent containers:

- clone and install `openbb-ai`
- clone `agents-for-openbb`
- install dependencies with `uv`
- apply runtime patch to `openbb_ai/models.py` to relax strict validation (the same strategy described in the Medium guide)

## Prereqs

- Docker Desktop (or Docker Engine + Compose v2)
- A Google Gemini API key from Google AI Studio

## Run

1. Create env file:

```bash
cd openbb-gemini
cp .env.example .env
```

2. Set your key in `.env`:

```dotenv
GEMINI_API_KEY=your_real_key
```

3. Build and start:

```bash
docker compose build --no-cache
docker compose up
```

If you want detached mode:

```bash
docker compose up -d
```

## Add to OpenBB Workspace

In OpenBB Copilot `+ Add Copilot`, register each URL:

- `Gemini Prompt Optimizer` -> `http://127.0.0.1:8095`
- `Gemini Raw Widget Data` -> `http://127.0.0.1:8096`
- `Gemini Reasoning Steps` -> `http://127.0.0.1:8097`
- `Gemini Raw Context Citations` -> `http://127.0.0.1:8098`
- `Gemini Tables` -> `http://127.0.0.1:8099`
- `Gemini PDF` -> `http://127.0.0.1:8100`
- `Gemini PDF Citations` -> `http://127.0.0.1:8101`

## Useful commands

```bash
docker compose ps
docker compose logs -f litellm
docker compose logs -f agent-30-raw-widget-data
docker compose down
```

## Notes

- The example agents expect OpenAI-style env vars. We route them to LiteLLM with:
  - `OPENAI_BASE_URL=http://litellm:4000`
  - `OPENAI_API_KEY=sk-fake-key`
- Port mappings use a unique host port per agent and internal `8095` in containers.
