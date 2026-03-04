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
  --namespace default

This script generates deploy/<agent-id>-config.yaml and then runs:
  01_preflight -> 02_build_image -> 03_import_image_to_k3s
  -> 04_create_db_bridge_secret -> 05_deploy_agent -> 06_verify_agent

If <package-dir>/Dockerfile is missing, a minimal one is generated automatically.
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
NAMESPACE="${NAMESPACE:-default}"

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
    --namespace)
      NAMESPACE="$2"
      shift 2
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

if [[ ! -f "$PACKAGE_DIR/pyproject.toml" ]]; then
  log "Package directory must contain pyproject.toml: $PACKAGE_DIR"
  exit 1
fi

if [[ -z "$DISPLAY_NAME" ]]; then
  DISPLAY_NAME="$AGENT_ID"
fi

if [[ -z "$TOOL_NAME" ]]; then
  TOOL_NAME="$FUNCTION_NAME"
fi

if [[ -z "$IMAGE_REPOSITORY" ]]; then
  IMAGE_REPOSITORY="docker.io/library/$AGENT_ID"
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

if [[ ! -f "$PACKAGE_DIR/Dockerfile" ]]; then
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

log "Starting automated deployment pipeline for $AGENT_ID"

NAMESPACE="$NAMESPACE" "$SCRIPT_DIR/01_preflight.sh"

AGENT_SOURCE_DIR="$PACKAGE_DIR" \
BASE_IMAGE="$BASE_IMAGE" \
CUSTOM_IMAGE="$CUSTOM_IMAGE" \
IMAGE_TAR="$IMAGE_TAR" \
"$SCRIPT_DIR/02_build_image.sh"

IMAGE_TAR="$IMAGE_TAR" "$SCRIPT_DIR/03_import_image_to_k3s.sh"

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

log "Completed. Release: $RELEASE_NAME"
