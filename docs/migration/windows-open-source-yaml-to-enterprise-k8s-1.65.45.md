# Open-Source YAML to SAM Enterprise k8s (Windows, 1.65.45)

This guide assumes a **two-team handoff**.

### Team 1: Application team

Team 1:

- works on Windows
- writes the agent YAML
- may also write the Python source files for custom tools
- has **no Docker install**
- does **not** build images
- hands the package to Team 2

### Team 2: Infrastructure team

Team 2:

- receives the handoff from Team 1
- builds the image if custom Python tools are used
- creates the Kubernetes secrets
- deploys the standalone Helm release to SAM Enterprise

Target runtime:

- `gcr.io/gcp-maas-prod/solace-agent-mesh-enterprise:1.65.45`

## 1. What Team 1 prepares

For each agent, Team 1 prepares:

1. `agent-config.yaml`
2. `agent-values.yaml`
3. `agent-secret-contract.md` or secret templates
4. `pyproject.toml` + `src/...` only if the agent uses custom Python tools

No Docker is needed on the Team 1 workstation.

If the agent uses only built-in tools, Team 1 usually only needs:

- `agent-config.yaml`
- `agent-values.yaml`
- `agent-secret-contract.md`

## 2. What changes from open source to enterprise

Open-source/source-style YAML often assumes:

- local filesystem artifacts
- memory or SQLite persistence
- local defaults like `localhost`
- inline credentials
- local source tree assumptions

Enterprise Kubernetes needs:

- broker settings from cluster secrets
- SQL persistence
- shared artifact storage
- no inline secrets
- a deployable image if custom Python tools are used

In practice, Team 1 is taking a source-style YAML and converting it into:

- one flattened runtime config for the agent
- one standalone Helm values file
- one clear list of secrets/env vars that infra must provide

## 3. The required YAML changes

### 3.0 Flatten the source YAML first

If the source YAML uses:

- `!include`
- YAML anchors
- local shared config files

Team 1 should flatten that into one self-contained `agent-config.yaml`.

Reason:

- Team 2 should not have to reconstruct local authoring conventions
- deployment troubleshooting is much easier with one final config file

### 3.1 Broker

Do not rely on local defaults.

Use:

```yaml
broker:
  dev_mode: ${SOLACE_DEV_MODE, false}
  broker_url: ${SOLACE_BROKER_URL}
  broker_username: ${SOLACE_BROKER_USERNAME}
  broker_password: ${SOLACE_BROKER_PASSWORD}
  broker_vpn: ${SOLACE_BROKER_VPN}
  temporary_queue: ${USE_TEMPORARY_QUEUES, true}
```

### 3.2 Model

Replace shared anchors or local includes with an explicit model block:

```yaml
model:
  model: ${LLM_SERVICE_GENERAL_MODEL_NAME}
  api_base: ${LLM_SERVICE_ENDPOINT}
  api_key: ${LLM_SERVICE_API_KEY}
```

### 3.3 Session persistence

Do not use `memory` or SQLite fallbacks for standalone enterprise agents.

Use:

```yaml
session_service:
  type: sql
  database_url: ${DATABASE_URL}
  default_behavior: PERSISTENT
```

### 3.4 Artifact storage

Do not use filesystem artifacts.

Use:

```yaml
artifact_service:
  type: ${ARTIFACT_SERVICE_TYPE, s3}
  bucket_name: ${S3_BUCKET_NAME}
  endpoint_url: ${S3_ENDPOINT_URL}
  aws_region: ${AWS_REGION, us-east-1}
  artifact_scope: namespace
```

### 3.5 Secrets

Do not hardcode any credentials in YAML.

Bad:

```yaml
tool_config:
  api_key: "hardcoded"
```

Good:

```yaml
tool_config:
  api_key: ${MY_API_KEY}
```

The same rule applies to:

- client secrets
- broker passwords
- database passwords
- S3 access keys
- external API tokens

## 4. If the YAML uses custom Python tools

If the YAML contains:

```yaml
tool_type: python
component_module: my_agent.tools
function_name: my_function
```

then Team 1 must provide:

- `pyproject.toml`
- `src/my_agent/...`
- any dependency list

Team 2 will then build an image from `solace-agent-mesh-enterprise:1.65.45`.

Important:

- `component_module` must be a real Python import path
- correct: `my_agent.tools`
- incorrect: `src.my_agent.tools`

## 5. `agent-values.yaml` shape

Minimum structure:

```yaml
deploymentMode: standalone
id: my-agent

global:
  persistence:
    namespaceId: my-sam-namespace-id

serviceAccount:
  name: solace-agent-mesh-sa

image:
  repository: my-registry.example.com/sam/my-agent
  tag: 1.0.0
  pullPolicy: IfNotPresent

solaceBroker:
  url: wss://broker.example.com:443
  username: my-broker-user
  password: my-broker-password
  vpn: my-vpn
  useTemporaryQueues: true

llmService:
  generalModelName: openai/bedrock-claude-4-5-sonnet
  endpoint: https://my-litellm.example.com
  apiKey: __SET_BY_INFRA__

persistence:
  existingSecrets:
    database: my-agent-db-bridge
    s3: ''

  s3:
    endpointUrl: https://my-artifact-store.example.com
    bucketName: my-sam-namespace-id
    accessKey: __SET_BY_INFRA__
    secretKey: __SET_BY_INFRA__
    region: us-east-1
```

Team 1 should treat this file as a template for Team 2.

That means:

- image repository/tag can be a requested target, even if Team 1 does not build it
- live passwords and keys should be placeholders or secret-backed values
- the file should already contain the correct deployment shape

## 6. Secret contract Team 1 should hand over

At minimum, infra needs:

- one DB bridge secret per standalone agent
- one secret for any custom tool credentials

The secret contract document should state:

- secret name
- required keys
- which YAML fields depend on those keys
- whether the value is mandatory or optional

Example DB bridge secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-agent-db-bridge
  namespace: default
type: Opaque
stringData:
  DATABASE_URL: postgresql+psycopg2://user:password@postgres-host:5432/my_agent_db
  PGHOST: postgres-host
  PGPORT: "5432"
  PGUSER: postgres
  PGPASSWORD: postgres-admin-password
```

## 7. What Team 2 does

After handoff, Team 2:

1. builds the image if custom Python tools are used
2. pushes the image to the enterprise registry
3. creates the Kubernetes secrets
4. deploys the standalone Helm release

If the agent has no custom Python tools, Team 2 may be able to use the standard enterprise image directly.

If the agent has custom Python tools, Team 2 must build a custom image that contains that package.

Helm pattern:

```powershell
helm upgrade --install my-agent solace-agent-mesh/sam-agent `
  -n default `
  -f .\my-agent-values.yaml `
  --set-file config.yaml=.\my-agent-config.yaml
```

## 8. Team 1 handoff checklist

Before Team 1 sends the package to Team 2, confirm:

1. no inline secrets remain in YAML
2. no `filesystem` artifact service remains
3. no `memory` or SQLite fallback remains for standalone session state
4. broker uses `${SOLACE_BROKER_*}` env vars
5. model uses `${LLM_SERVICE_*}` env vars
6. `DATABASE_URL` is used for standalone agent session state
7. `component_module` is a real import path
8. `agent-values.yaml` points to the intended image name
9. any `!include` or local anchor dependency has been flattened out
10. Team 2 can understand the required secret names and keys without asking for source-repo context

## 9. What Team 1 hands over

Minimum handoff package:

1. `agent-config.yaml`
2. `agent-values.yaml`
3. `agent-secret-contract.md`

If custom Python tools exist, add:

4. `pyproject.toml`
5. `src/...`
6. dependency notes if non-standard packages are required

## 10. Bottom line

For this customer workflow, Team 1 only needs to:

- prepare enterprise-ready `config.yaml`
- prepare enterprise-ready `values.yaml`
- define the secret contract
- provide Python package files only if custom tools exist

No Docker is needed on the Team 1 machine.  
Team 2 handles image build, secrets, and deployment.
