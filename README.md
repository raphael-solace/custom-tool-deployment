# Custom Tool Deployment (Standalone SAM Agent)

This repository shows how to deploy a **single standalone Solace Agent Mesh agent** with a **custom Python tool** on an existing cluster.

It is designed to be shared safely:
- secret-bearing/generated files are ignored by `.gitignore`
- reusable scripts automate build/import/deploy/verify

## Prerequisites

1. Local tools: `docker`, `ssh`, `scp`, `expect`, `kubectl`, `helm`, `jq`
2. SSH access to k3s host with sudo (for `k3s ctr images import`)
3. Repo-level `.env` file:

```text
ssh your-user@your-k8s-host
pwd: your-ssh-password
```

Use [`.env.example`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/.env.example) as template.

## Step-by-step (manual flow)

### 1) Write custom echo agent + tool

Create your package with a deterministic tool function.

Reference implementation:
- [custom-echo-agent/src/custom_echo_agent/tools.py](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/custom-echo-agent/src/custom_echo_agent/tools.py)

Expected function contract:

```python
async def healthcheck_echo(name: str, tool_context=None, tool_config=None) -> dict
```

### 2) Package in TOML

Define your Python package metadata in `pyproject.toml`.

Reference:
- [custom-echo-agent/pyproject.toml](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/custom-echo-agent/pyproject.toml)

### 3) Extend the base image and install the package

Create a Dockerfile that extends:
- `gcr.io/gcp-maas-prod/solace-agent-mesh-enterprise:1.65.45`

Install your package with `pip install .`.

Reference:
- [custom-echo-agent/Dockerfile](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/custom-echo-agent/Dockerfile)

Build/export image:

```bash
./scripts/02_build_image.sh
```

### 4) Import the image into k3s

Import your built tar into remote containerd:

```bash
./scripts/03_import_image_to_k3s.sh
```

### 5) Create standalone agent config

Create app config YAML wiring your Python tool:
- `tool_type: python`
- `component_module: your_module.tools`
- `function_name: your_function`

Reference:
- [deploy/custom-echo-agent-config.yaml](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/deploy/custom-echo-agent-config.yaml)

### 6) Use live broker/LLM/S3 from the cluster

Generate values from existing working SAM secrets and create DB bridge secret (`DATABASE_URL` compatibility for standalone mode):

```bash
./scripts/04_create_db_bridge_secret.sh
```

Then deploy and verify:

```bash
./scripts/05_deploy_agent.sh
./scripts/06_verify_agent.sh
```

## Full scripted pipeline (existing custom echo agent)

```bash
./scripts/01_preflight.sh
./scripts/02_build_image.sh
./scripts/03_import_image_to_k3s.sh
./scripts/04_create_db_bridge_secret.sh
./scripts/05_deploy_agent.sh
./scripts/06_verify_agent.sh
```

## Great simplification: builders only do step 1 + 2, then one command

After you implement your tool code and `pyproject.toml`, run one command:

```bash
./scripts/00_autodeploy_from_package.sh \
  --agent-id my-agent \
  --package-dir /abs/path/to/my-agent-package \
  --module my_agent.tools \
  --function healthcheck_echo
```

This automatically:
1. Generates `deploy/<agent-id>-config.yaml`
2. Generates a minimal Dockerfile if missing (base image + `pip install .`)
3. Builds custom image from your package directory
4. Imports image into k3s
5. Creates DB bridge secret + `deploy/<agent-id>-values.generated.yaml`
6. Deploys Helm release `<agent-id>`
7. Verifies rollout, logs, and Python import/call

## Files to know

- Scripts: [`scripts/`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/scripts)
- Runbook: [standalone-agent-deployment-runbook.md](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/standalone-agent-deployment-runbook.md)
- Example package: [`custom-echo-agent/`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/custom-echo-agent)

## Security notes

- `deploy/*-values.generated.yaml` contains live credentials and is gitignored.
- `.env` is gitignored.
- Runtime logs/artifacts are gitignored.
