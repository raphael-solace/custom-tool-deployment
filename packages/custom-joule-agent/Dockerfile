FROM gcr.io/gcp-maas-prod/solace-agent-mesh-enterprise:1.97.2

USER 0
WORKDIR /app
COPY requirements.txt ./requirements.txt
RUN python -m pip install --no-cache-dir -r requirements.txt
COPY src ./src
RUN chown -R 999:999 /app/src

USER 999
