FROM gcr.io/gcp-maas-prod/solace-agent-mesh-enterprise:1.97.2

USER 0
WORKDIR /app

COPY src/sam_bedrock_agent /app/sam_bedrock_agent
ENV PYTHONPATH=/app

USER 999
