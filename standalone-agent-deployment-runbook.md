# Standalone Custom Agent Deployment Runbook (Single Agent)

This runbook follows the official standalone deployment guide and deploys **one** custom agent (`custom-echo-agent`) into namespace `default`.

## Scope

- One standalone `sam-agent` release
- One custom Python tool package
- One DB bridge secret for standalone compatibility
- Full verification (rollout + logs + python import)

## Prerequisites

1. Local machine has `docker`, `ssh`, `scp`, `expect`, `helm`, `kubectl`, `jq`.
2. `.env` exists in repo root in this format:

```text
ssh your-user@your-k8s-host
pwd: your-password
```

3. Remote host has:
- `kubectl` access to target cluster
- `helm` with `solace-agent-mesh` repo
- `k3s` and `sudo` permission (for image import)

## One-Command Sequence (Scripted)

Run from repo root:

```bash
./scripts/01_preflight.sh
./scripts/02_build_image.sh
./scripts/03_import_image_to_k3s.sh
./scripts/04_create_db_bridge_secret.sh
./scripts/05_deploy_agent.sh
./scripts/06_verify_agent.sh
```

## What Each Script Does

1. `01_preflight.sh`
- Verifies local tools
- Verifies remote access/context
- Confirms service account + rolebinding
- Saves baseline snapshot to `deploy/baseline-snapshot.txt`

2. `02_build_image.sh`
- Builds custom image from `custom-echo-agent/Dockerfile`
- Uses base image `gcr.io/gcp-maas-prod/solace-agent-mesh-enterprise:1.65.45`
- If pull fails, exports base image from k3s node and loads locally
- Saves tar to `artifacts/custom-echo-agent-local-v1.tar`

3. `03_import_image_to_k3s.sh`
- Copies image tar to remote node
- Imports into `k3s` containerd
- Validates imported image reference exists

4. `04_create_db_bridge_secret.sh`
- Creates `custom-echo-agent-db-bridge` with:
  - `DATABASE_URL`
  - `PGHOST`
  - `PGPORT`
  - `PGUSER`
  - `PGPASSWORD`
- Generates `deploy/custom-echo-agent-values.generated.yaml` using live broker/LLM/S3 values from cluster

5. `05_deploy_agent.sh`
- Runs Helm server dry-run
- Installs/upgrades release `custom-echo-agent`

6. `06_verify_agent.sh`
- Checks rollout status
- Captures db-init and sam logs
- Runs in-pod Python import + tool call check
- Saves verification report to `deploy/verification-custom-echo-agent.txt`

## Manual Fallback (Guide Mapping)

### Guide Step 1: Agent config
Use:
- `deploy/custom-echo-agent-config.yaml`

### Guide Step 2: Values file
Use generated file:
- `deploy/custom-echo-agent-values.generated.yaml`

### Guide Step 3: Service account
Verify:

```bash
kubectl get sa solace-agent-mesh-sa -n default
kubectl get rolebinding agent-mesh-rolebinding-sam -n default
```

### Compatibility pre-step: DB bridge secret
Create via script:

```bash
./scripts/04_create_db_bridge_secret.sh
```

### Guide Step 4: Install

```bash
helm upgrade -i custom-echo-agent solace-agent-mesh/sam-agent \
  -n default \
  -f deploy/custom-echo-agent-values.generated.yaml \
  --set-file config.yaml=deploy/custom-echo-agent-config.yaml
```

### Guide Step 5: Verify

```bash
kubectl rollout status deployment/custom-echo-agent -n default
kubectl logs -n default deployment/custom-echo-agent -c db-init --tail=80
kubectl logs -n default deployment/custom-echo-agent -c sam --tail=120
```

## UI Access From Laptop (Port-Forward)

Use two terminals.

Terminal 1 (on k8s host):

```bash
kubectl -n default port-forward svc/agent-mesh 8000:80 8080:8080 5050:5050
```

Terminal 2 (on laptop):

```bash
ssh -N -L 8000:127.0.0.1:8000 -L 8080:127.0.0.1:8080 -L 5050:127.0.0.1:5050 rcaillon@192.168.31.57
```

Open:
- `http://127.0.0.1:8000` (UI)
- `http://127.0.0.1:8080/docs` (Platform API docs)

## Troubleshooting

| Symptom | Check | Fix |
|---|---|---|
| Helm dry-run fails on DATABASE_URL | `kubectl get secret custom-echo-agent-db-bridge -n default -o yaml` | Re-run `./scripts/04_create_db_bridge_secret.sh` |
| Pod ImagePullBackOff | `sudo k3s ctr -n k8s.io images ls | rg custom-echo-agent` on node | Re-run scripts 02 and 03 |
| db-init fails auth/connection | `kubectl logs deployment/custom-echo-agent -n default -c db-init` | Verify bridge secret keys + postgres host/port/user/password |
| sam container starts but tool import fails | `kubectl exec ... python -c "import custom_echo_agent.tools"` | Rebuild image and re-import (scripts 02 + 03), then redeploy |
| UI loads but Agents page says "Failed to fetch" | `curl -i -X OPTIONS -H "Origin: http://127.0.0.1:8000" -H "Access-Control-Request-Method: GET" http://127.0.0.1:8080/api/v1/platform/agents` | Ensure CORS allows localhost in `agent-mesh-environment` (`CORS_ALLOWED_ORIGIN_REGEX`), restart `agent-mesh-core`, and keep `8000/8080/5050` forwarded |
| Browser calls `https://sam.your-domain.com/...` from localhost UI | `curl http://127.0.0.1:8000/api/v1/config | jq '{frontend_server_url,frontend_platform_server_url}'` | Patch `agent-mesh-environment` keys (`FRONTEND_SERVER_URL`, `PLATFORM_SERVICE_URL`, `WEBUI_FRONTEND_SERVER_URL`, `WEBUI_FRONTEND_URL`) to localhost URLs, restart `agent-mesh-core`, then hard-refresh browser |

## Rollback

```bash
helm uninstall custom-echo-agent -n default
```

Optional cleanup:

```bash
kubectl delete secret custom-echo-agent-db-bridge -n default
```

## Safety Notes

- Scripts avoid printing raw secret values.
- Generated values file contains live credentials; keep it local and protected.
- Existing SAM agents/gateways are not modified; deployment is additive.
