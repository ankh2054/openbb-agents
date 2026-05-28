# OpenBB + Gemini Docker setup

Containerized stack to run OpenBB example agents through Gemini via LiteLLM behind `nginx-proxy` + ACME.

## What this deploys

- `litellm` bridge on `http://127.0.0.1:4000` (OpenAI-compatible API over Gemini)
- `20-financial-prompt-optimizer` on `https://prompt-optimizer.agent.sentnl.io`
- `30-vanilla-agent-raw-widget-data` on `https://raw-widget-data.agent.sentnl.io`
- `31-vanilla-agent-reasoning-steps` on `https://reasoning-steps.agent.sentnl.io`
- `32-vanilla-agent-raw-widget-data-citations` on `https://raw-widget-citations.agent.sentnl.io`
- `34-vanilla-agent-tables` on `https://tables.agent.sentnl.io`
- `36-vanilla-agent-pdf-citations` on `https://pdf-citations.agent.sentnl.io`

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
cp .env.example .env
```

2. Set your key in `.env`:

```dotenv
GEMINI_API_KEY=your_real_key
LETSENCRYPT_EMAIL=ops@sentnl.io
```

3. Build and start:

```bash
docker network create cookz-net || true
docker compose build --no-cache
docker compose up
```

If you want detached mode:

```bash
docker compose up -d
```

## Add to OpenBB Workspace

In OpenBB Copilot `+ Add Copilot`, register each URL:

- `Gemini Prompt Optimizer` -> `https://prompt-optimizer.agent.sentnl.io`
- `Gemini Raw Widget Data` -> `https://raw-widget-data.agent.sentnl.io`
- `Gemini Reasoning Steps` -> `https://reasoning-steps.agent.sentnl.io`
- `Gemini Raw Context Citations` -> `https://raw-widget-citations.agent.sentnl.io`
- `Gemini Tables` -> `https://tables.agent.sentnl.io`
- `Gemini PDF Citations` -> `https://pdf-citations.agent.sentnl.io`

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
- Agent containers are not host-exposed; they use `expose: 8095` and are reached through `nginx-proxy` on external Docker network `cookz-net`.
