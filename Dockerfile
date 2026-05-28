FROM python:3.11-slim

# System dependencies
RUN apt-get update && apt-get install -y git build-essential curl && rm -rf /var/lib/apt/lists/*

# Install uv (fast package installer)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

WORKDIR /app

# Step 1: install openbb-ai SDK
RUN git clone https://github.com/OpenBB-finance/openbb-ai.git
WORKDIR /app/openbb-ai
RUN rm -f poetry.lock

# Keep pydantic flexible to avoid version deadlocks
RUN if [ -f pyproject.toml ]; then sed -i 's/pydantic = "==2.7.1"/pydantic = ">=2.7.1"/' pyproject.toml; fi
RUN uv pip install --system --prerelease=allow .

# Step 2: clone agents repo; runtime service selects AGENT_DIR
WORKDIR /app
RUN git clone https://github.com/OpenBB-finance/agents-for-openbb.git
ARG AGENT_DIR
WORKDIR /app/agents-for-openbb/${AGENT_DIR}

# Shared runtime deps used by example agents
# pdfplumber is required by 36-vanilla-agent-pdf-citations.
RUN uv pip install --system --prerelease=allow \
    langchain-openai \
    fastapi \
    uvicorn \
    python-dotenv \
    sse-starlette \
    pdfplumber

# Smart patch for stricter model validation in openbb-ai
RUN echo "import re" > /app/patcher.py && \
    echo "target_file = '/usr/local/lib/python3.11/site-packages/openbb_ai/models.py'" >> /app/patcher.py && \
    echo "print(f'Patching {target_file} ...')" >> /app/patcher.py && \
    echo "try:" >> /app/patcher.py && \
    echo "    with open(target_file, 'r') as f: content = f.read()" >> /app/patcher.py && \
    echo "    content = re.sub(r'extra_state: Dict\\[str, Any\\]', 'extra_state: Dict[str, Any] | None = None', content)" >> /app/patcher.py && \
    echo "    content = content.replace('content: str | LlmClientFunctionCall = Field(', 'content: str | LlmClientFunctionCall | None = Field(default=None, ')" >> /app/patcher.py && \
    echo "    content = re.sub(r'content: str$', 'content: str | None = None', content, flags=re.MULTILINE)" >> /app/patcher.py && \
    echo "    with open(target_file, 'w') as f: f.write(content)" >> /app/patcher.py && \
    echo "    print('SUCCESS: File patched safely.')" >> /app/patcher.py && \
    echo "except Exception as e:" >> /app/patcher.py && \
    echo "    print(f'ERROR: {e}')" >> /app/patcher.py && \
    echo "    exit(1)" >> /app/patcher.py

RUN python3 /app/patcher.py

EXPOSE 8095
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8095"]
