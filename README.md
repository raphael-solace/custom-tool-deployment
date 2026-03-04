# Custom Tool Deployment (Standalone SAM Agent)

This repository shows how to deploy a **single standalone Solace Agent Mesh agent** with **custom Python tools** on an existing cluster.

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

### 1) Write custom agent + tools

Create your package with the tool functions you need.

Reference implementation:
- [custom-echo-agent/src/custom_echo_agent/tools.py](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/custom-echo-agent/src/custom_echo_agent/tools.py)

Example function contracts:

```python
async def healthcheck_echo(name: str, tool_context=None, tool_config=None) -> dict
async def simple_rag(query: str, top_k: int = 2, tool_context=None, tool_config=None) -> dict
async def query_external_postgres(sql: str, max_rows: int = 50, tool_context=None, tool_config=None) -> dict
async def publish_event(topic: str, payload: dict, tool_context=None, tool_config=None) -> dict
async def inspect_pdf(file_path: str | None = None, query: str | None = None, tool_context=None, tool_config=None) -> dict
```

### 2) Package in TOML

Define your Python package metadata in `pyproject.toml` and add any required dependencies (example: `pypdf` for PDF parsing).

Minimal example:

```toml
[build-system]
requires = ["setuptools>=68", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "my-agent"
version = "0.1.0"
description = "Custom Python tools for standalone Solace Agent Mesh deployment"
readme = "README.md"
requires-python = ">=3.11"

[tool.setuptools]
package-dir = { "" = "src" }

[tool.setuptools.packages.find]
where = ["src"]
```

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

If your cluster pulls from an image repository instead of local k3s import, use:
- `--image-distribution-mode registry`
- image push during build (`--push-image`, default in registry mode)

### 5) Create standalone agent config

Create app config YAML wiring your Python tools:
- `tool_type: python`
- `component_module: your_module.tools`
- `function_name: your_function`
- `tool_config` for runtime settings (for example `allowed_roots` for `inspect_pdf`)
- `extract_content_from_artifact_config.supported_binary_mime_types` with PDF MIME types so built-in artifact extraction can read attached PDFs

Reference:
- [deploy/custom-echo-agent-config.yaml](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/deploy/custom-echo-agent-config.yaml)

Minimal hardening block:

```yaml
extract_content_from_artifact_config:
  supported_binary_mime_types:
    - "application/pdf"
    - "application/x-pdf"
```

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

Optional targeted check for PDF tool import/call:

```bash
NAMESPACE=default RELEASE_NAME=custom-echo-agent \
VERIFY_IMPORT_MODULE=custom_echo_agent.tools \
VERIFY_FUNCTION_NAME=inspect_pdf \
VERIFY_FUNCTION_ARG=/tmp/notfound.pdf \
./scripts/06_verify_agent.sh
```

Attachment behavior for `inspect_pdf`:
- If `file_path` points to `/tmp` or `/app`, it reads from container filesystem.
- If local path is missing, it tries chat artifacts via `tool_context.list_artifacts()` and `load_artifact()`.
- If still not found, it falls back to shared ArtifactService lookup using candidate app/session contexts from invocation metadata.
- If shared lookup still misses, it scans shared artifact storage (S3/SeaweedFS bucket) for matching PDF keys.
- If `file_path` is omitted, it selects the latest attached PDF artifact.
- Optional override parameters: `source_user_id`, `source_app_name`, `source_session_id`, `bucket_prefix`.

Broker publish behavior for `publish_event`:
- Uses runtime broker credentials (`SOLACE_BROKER_*`) by default.
- Publishes direct events to the provided Solace topic.
- For private/self-signed broker certs, set `tool_config.disable_certificate_validation: true` (cluster-specific tradeoff).

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
2. Scaffolds missing package files (`pyproject.toml`, `README.md`, `src/<module>.py`)
3. Generates a minimal Dockerfile if missing (base image + `pip install .`)
4. Builds custom image from your package directory
5. Imports image into k3s
6. Creates DB bridge secret + `deploy/<agent-id>-values.generated.yaml`
7. Deploys Helm release `<agent-id>`
8. Verifies rollout, logs, and Python import/call

Generated config includes PDF hardening for built-in `extract_content_from_artifact`.

If you want strict mode (no auto-generated files), add `--no-scaffold`.

### Registry mode (two-step: build first, deploy later)

Step A: build/push image only

```bash
./scripts/00_build_image_from_package.sh \
  --agent-id my-agent \
  --package-dir /abs/path/to/my-agent-package \
  --module my_agent.tools \
  --function healthcheck_echo \
  --image-repository ghcr.io/my-org/my-agent \
  --image-tag v1 \
  --image-distribution-mode registry
```

`registry` mode pushes by default. Use `--no-push-image` if you only want a local build.

Step B: deploy using prebuilt image

```bash
./scripts/07_deploy_from_prebuilt_image.sh \
  --agent-id my-agent \
  --package-dir /abs/path/to/my-agent-package \
  --module my_agent.tools \
  --function healthcheck_echo \
  --image-repository ghcr.io/my-org/my-agent \
  --image-tag v1 \
  --image-distribution-mode registry
```

## Files to know

- Scripts: [`scripts/`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/scripts)
- Runbook: [standalone-agent-deployment-runbook.md](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/standalone-agent-deployment-runbook.md)
- Example package: [`custom-echo-agent/`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/custom-echo-agent)

## Security notes

- `deploy/*-values.generated.yaml` contains live credentials and is gitignored.
- `.env` is gitignored.
- Runtime logs/artifacts are gitignored.
