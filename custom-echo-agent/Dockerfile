FROM gcr.io/gcp-maas-prod/solace-agent-mesh-enterprise:1.65.45

USER 0
WORKDIR /tmp/custom-echo-agent
COPY pyproject.toml README.md ./
COPY src ./src

RUN python -m pip install --no-cache-dir .

WORKDIR /app
USER 999
