#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/00_autodeploy_from_package.sh \
    --agent-id custom-echo-agent \
    --package-dir /abs/path/to/agent-package \
    --module custom_echo_agent.tools \
    --function healthcheck_echo

Optional:
  --display-name "Custom Echo Agent"
  --tool-name healthcheck_echo
  --image-repository docker.io/library/custom-echo-agent
  --image-tag local-v1
  --base-image gcr.io/gcp-maas-prod/solace-agent-mesh-enterprise:1.65.45
  --image-distribution-mode k3s|registry
  --phase all|image|deploy
  --push-image | --no-push-image
  --namespace default
  --no-scaffold

This script generates deploy/<agent-id>-config.yaml and then runs:
  01_preflight -> 02_build_image -> 03_import_image_to_k3s (k3s mode only)
  -> 04_create_db_bridge_secret -> 05_deploy_agent -> 06_verify_agent

If scaffolding is enabled (default), and files are missing, it auto-generates:
  - pyproject.toml
  - README.md
  - src/<module>.py with a deterministic async tool function
  - Dockerfile

Two-phase usage for registry workflows:
  1) --phase image   (build/push image)
  2) --phase deploy  (reuse image and deploy)
EOF
}

AGENT_ID=""
PACKAGE_DIR=""
MODULE=""
FUNCTION_NAME=""
DISPLAY_NAME=""
TOOL_NAME=""
IMAGE_REPOSITORY=""
IMAGE_TAG="local-v1"
BASE_IMAGE="gcr.io/gcp-maas-prod/solace-agent-mesh-enterprise:1.65.45"
IMAGE_DISTRIBUTION_MODE="k3s"
PHASE="all"
PUSH_IMAGE=""
NAMESPACE="${NAMESPACE:-default}"
SCAFFOLD="true"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent-id)
      AGENT_ID="$2"
      shift 2
      ;;
    --package-dir)
      PACKAGE_DIR="$2"
      shift 2
      ;;
    --module)
      MODULE="$2"
      shift 2
      ;;
    --function)
      FUNCTION_NAME="$2"
      shift 2
      ;;
    --display-name)
      DISPLAY_NAME="$2"
      shift 2
      ;;
    --tool-name)
      TOOL_NAME="$2"
      shift 2
      ;;
    --image-repository)
      IMAGE_REPOSITORY="$2"
      shift 2
      ;;
    --image-tag)
      IMAGE_TAG="$2"
      shift 2
      ;;
    --base-image)
      BASE_IMAGE="$2"
      shift 2
      ;;
    --image-distribution-mode)
      IMAGE_DISTRIBUTION_MODE="$2"
      shift 2
      ;;
    --phase)
      PHASE="$2"
      shift 2
      ;;
    --push-image)
      PUSH_IMAGE="true"
      shift 1
      ;;
    --no-push-image)
      PUSH_IMAGE="false"
      shift 1
      ;;
    --namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    --no-scaffold)
      SCAFFOLD="false"
      shift 1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$AGENT_ID" || -z "$PACKAGE_DIR" || -z "$MODULE" || -z "$FUNCTION_NAME" ]]; then
  log "Missing required arguments"
  usage
  exit 1
fi

if [[ "$IMAGE_DISTRIBUTION_MODE" != "k3s" && "$IMAGE_DISTRIBUTION_MODE" != "registry" ]]; then
  log "Unsupported --image-distribution-mode: $IMAGE_DISTRIBUTION_MODE (expected k3s|registry)"
  exit 1
fi

if [[ "$PHASE" != "all" && "$PHASE" != "image" && "$PHASE" != "deploy" ]]; then
  log "Unsupported --phase: $PHASE (expected all|image|deploy)"
  exit 1
fi

RUN_IMAGE_PHASE="false"
RUN_DEPLOY_PHASE="false"
if [[ "$PHASE" == "all" || "$PHASE" == "image" ]]; then
  RUN_IMAGE_PHASE="true"
fi
if [[ "$PHASE" == "all" || "$PHASE" == "deploy" ]]; then
  RUN_DEPLOY_PHASE="true"
fi

if [[ -z "$PUSH_IMAGE" ]]; then
  if [[ "$IMAGE_DISTRIBUTION_MODE" == "registry" ]]; then
    PUSH_IMAGE="true"
  else
    PUSH_IMAGE="false"
  fi
fi

mkdir -p "$PACKAGE_DIR"

MODULE_FILE_REL="src/${MODULE//./\/}.py"
MODULE_FILE="$PACKAGE_DIR/$MODULE_FILE_REL"
MODULE_DIR="$(dirname "$MODULE_FILE")"

if [[ -z "$DISPLAY_NAME" ]]; then
  DISPLAY_NAME="$AGENT_ID"
fi

if [[ -z "$TOOL_NAME" ]]; then
  TOOL_NAME="$FUNCTION_NAME"
fi

if [[ -z "$IMAGE_REPOSITORY" ]]; then
  IMAGE_REPOSITORY="docker.io/library/$AGENT_ID"
fi

if [[ "$RUN_IMAGE_PHASE" == "true" && "$SCAFFOLD" == "true" ]]; then
  if [[ ! -f "$PACKAGE_DIR/pyproject.toml" ]]; then
    log "No pyproject.toml found; generating a minimal package definition"
    cat > "$PACKAGE_DIR/pyproject.toml" <<TOML
[build-system]
requires = ["setuptools>=68", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "${AGENT_ID}"
version = "0.1.0"
description = "Custom Python tools for standalone Solace Agent Mesh deployment"
readme = "README.md"
requires-python = ">=3.11"
authors = [{ name = "custom-tool-deployment" }]

[tool.setuptools]
package-dir = { "" = "src" }

[tool.setuptools.packages.find]
where = ["src"]
TOML
  fi

  if [[ ! -f "$PACKAGE_DIR/README.md" ]]; then
    cat > "$PACKAGE_DIR/README.md" <<MD
# ${AGENT_ID}

Custom Python tools package for Solace Agent Mesh standalone deployment.
MD
  fi

  if [[ ! -f "$MODULE_FILE" ]]; then
    log "No module file found; generating tool module: $MODULE_FILE_REL"
    mkdir -p "$MODULE_DIR"

    # Ensure importable Python package directories under src/.
    PKG_DIR="$MODULE_DIR"
    while [[ "$PKG_DIR" != "$PACKAGE_DIR/src" && "$PKG_DIR" != "$PACKAGE_DIR" ]]; do
      touch "$PKG_DIR/__init__.py"
      PKG_DIR="$(dirname "$PKG_DIR")"
    done

    cat > "$MODULE_FILE" <<PY
from typing import Any, Dict, Optional

from google.adk.tools import ToolContext


async def ${FUNCTION_NAME}(
    name: str,
    tool_context: Optional[ToolContext] = None,
    tool_config: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    prefix = "HELLO"
    if tool_config and isinstance(tool_config, dict):
        prefix = str(tool_config.get("prefix", "HELLO"))

    return {
        "status": "ok",
        "tool": "${FUNCTION_NAME}",
        "message": f"{prefix}::{name}",
        "deterministic": True,
        "has_tool_context": tool_context is not None,
    }
PY
  fi
fi

if [[ "$RUN_IMAGE_PHASE" == "true" && ! -f "$PACKAGE_DIR/pyproject.toml" ]]; then
  log "Package directory must contain pyproject.toml (or run without --no-scaffold): $PACKAGE_DIR"
  exit 1
fi

RELEASE_NAME="$AGENT_ID"
DB_SECRET_NAME="${AGENT_ID}-db-bridge"
CONFIG_FILE="$ROOT_DIR/deploy/${AGENT_ID}-config.yaml"
VALUES_FILE="$ROOT_DIR/deploy/${AGENT_ID}-values.generated.yaml"
IMAGE_TAR="$ROOT_DIR/artifacts/${AGENT_ID}-${IMAGE_TAG}.tar"
CUSTOM_IMAGE="${IMAGE_REPOSITORY}:${IMAGE_TAG}"

mkdir -p "$ROOT_DIR/deploy" "$ROOT_DIR/artifacts"

log "Generating standalone agent config: $CONFIG_FILE"
cat > "$CONFIG_FILE" <<YAML
log:
  stdout_log_level: INFO
  log_file_level: INFO
  log_file: "${AGENT_ID}.log"

apps:
  - name: "${AGENT_ID}"
    app_base_path: "."
    app_module: "solace_agent_mesh.agent.sac.app"
    broker:
      dev_mode: \${SOLACE_DEV_MODE, false}
      broker_url: \${SOLACE_BROKER_URL, ws://localhost:8080}
      broker_username: \${SOLACE_BROKER_USERNAME, default}
      broker_password: \${SOLACE_BROKER_PASSWORD, default}
      broker_vpn: \${SOLACE_BROKER_VPN, default}
      temporary_queue: \${USE_TEMPORARY_QUEUES, true}

    app_config:
      namespace: "\${NAMESPACE}"
      supports_streaming: true
      agent_name: "${AGENT_ID}"
      display_name: "${DISPLAY_NAME}"

      instruction: |
        You are a deterministic deployment validation agent.
        Use ${TOOL_NAME} when asked for a health check or echo response.
        Keep responses short and precise.

      model:
        model: "\${LLM_SERVICE_GENERAL_MODEL_NAME}"
        api_base: "\${LLM_SERVICE_ENDPOINT}"
        api_key: "\${LLM_SERVICE_API_KEY}"

      tools:
        - tool_type: python
          component_module: "${MODULE}"
          component_base_path: "."
          function_name: "${FUNCTION_NAME}"
          tool_name: "${TOOL_NAME}"
          tool_config:
            prefix: "HELLO"

      session_service:
        type: \${PERSISTENCE_TYPE, sql}
        database_url: \${DATABASE_URL}
        default_behavior: PERSISTENT

      artifact_service:
        type: \${ARTIFACT_SERVICE_TYPE, s3}
        bucket_name: \${S3_BUCKET_NAME}
        endpoint_url: \${S3_ENDPOINT_URL}
        aws_region: \${AWS_REGION, us-east-1}
        artifact_scope: namespace

      artifact_handling_mode: reference
      enable_embed_resolution: true
      enable_artifact_content_instruction: true
      extract_content_from_artifact_config:
        supported_binary_mime_types:
          - "application/pdf"
          - "application/x-pdf"

      agent_card:
        description: "Standalone custom agent (${AGENT_ID})"
        defaultInputModes: ["text"]
        defaultOutputModes: ["text"]
        skills:
          - id: "${TOOL_NAME}"
            name: "${TOOL_NAME}"
            description: "Custom Python tool"

      agent_card_publishing:
        interval_seconds: 10

      agent_discovery:
        enabled: false

      inter_agent_communication:
        allow_list: []
        request_timeout_seconds: 30
YAML

if [[ "$RUN_IMAGE_PHASE" == "true" && ! -f "$PACKAGE_DIR/Dockerfile" ]]; then
  if [[ "$SCAFFOLD" != "true" ]]; then
    log "Missing Dockerfile and scaffolding disabled (--no-scaffold): $PACKAGE_DIR/Dockerfile"
    exit 1
  fi

  log "No Dockerfile found in package dir; generating minimal Dockerfile automatically"
  cat > "$PACKAGE_DIR/Dockerfile" <<DOCKERFILE
FROM ${BASE_IMAGE}

USER 0
WORKDIR /tmp/agent-package
COPY . .

RUN python -m pip install --no-cache-dir .

WORKDIR /app
USER 999
DOCKERFILE
fi

log "Starting pipeline for $AGENT_ID (phase=$PHASE mode=$IMAGE_DISTRIBUTION_MODE)"

if [[ "$RUN_IMAGE_PHASE" == "true" ]]; then
  AGENT_SOURCE_DIR="$PACKAGE_DIR" \
  BASE_IMAGE="$BASE_IMAGE" \
  CUSTOM_IMAGE="$CUSTOM_IMAGE" \
  IMAGE_TAR="$IMAGE_TAR" \
  IMAGE_DISTRIBUTION_MODE="$IMAGE_DISTRIBUTION_MODE" \
  PUSH_IMAGE="$PUSH_IMAGE" \
  "$SCRIPT_DIR/02_build_image.sh"
fi

if [[ "$RUN_DEPLOY_PHASE" == "true" ]]; then
  if [[ "$RUN_IMAGE_PHASE" == "true" ]]; then
    NAMESPACE="$NAMESPACE" "$SCRIPT_DIR/01_preflight.sh"
  else
    SKIP_DOCKER_CHECK="true" NAMESPACE="$NAMESPACE" "$SCRIPT_DIR/01_preflight.sh"
  fi

  if [[ "$IMAGE_DISTRIBUTION_MODE" == "k3s" ]]; then
    IMAGE_TAR="$IMAGE_TAR" "$SCRIPT_DIR/03_import_image_to_k3s.sh"
  else
    log "Registry mode selected; skipping k3s image import"
  fi

  NAMESPACE="$NAMESPACE" \
  AGENT_ID="$AGENT_ID" \
  DB_SECRET_NAME="$DB_SECRET_NAME" \
  VALUES_OUT="$VALUES_FILE" \
  IMAGE_REPOSITORY="$IMAGE_REPOSITORY" \
  IMAGE_TAG="$IMAGE_TAG" \
  "$SCRIPT_DIR/04_create_db_bridge_secret.sh"

  NAMESPACE="$NAMESPACE" \
  RELEASE_NAME="$RELEASE_NAME" \
  VALUES_FILE="$VALUES_FILE" \
  CONFIG_FILE="$CONFIG_FILE" \
  "$SCRIPT_DIR/05_deploy_agent.sh"

  NAMESPACE="$NAMESPACE" \
  RELEASE_NAME="$RELEASE_NAME" \
  VERIFY_IMPORT_MODULE="$MODULE" \
  VERIFY_FUNCTION_NAME="$FUNCTION_NAME" \
  "$SCRIPT_DIR/06_verify_agent.sh"
fi

log "Completed. Release: $RELEASE_NAME (phase=$PHASE)"
