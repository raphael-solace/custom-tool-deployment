# Open-Source SAM to k8s1 Mapping

This document captures the changes required to take the open-source/source-style Solace Agent Mesh configs in this repo and make them deploy correctly on `emeak8s1`.

It is not a generic SAM guide. It is the concrete delta between:

- source/open-source style configs such as:
  - [`custom-joule-agent/configs/shared_config.yaml`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/packages/custom-joule-agent/configs/shared_config.yaml)
  - [`custom-joule-agent/configs/services/platform.yaml`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/packages/custom-joule-agent/configs/services/platform.yaml)
  - [`custom-joule-agent/configs/gateways/webui.yaml`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/packages/custom-joule-agent/configs/gateways/webui.yaml)
  - [`custom-joule-agent/configs/agents/*.yaml`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/packages/custom-joule-agent/configs/agents)
- the live k8s1 runtime described in:
  - [`k8s1-runtime-inventory.md`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/docs/reference/k8s1-runtime-inventory.md)
  - generated standalone values in [`deploy/rfq`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/deploy/rfq)

## 1. Short answer

Yes, this makes sense.

The upstream/source configs assume local-style defaults in several places:

- artifacts on local filesystem
- SQLite fallbacks for platform/webui/session persistence
- in-memory session service in shared config
- inline demo credentials in some agent YAMLs
- no cluster-specific Helm values layer

The k8s1 deployment does not use those defaults.

On k8s1, the deployment is wired to:

- PostgreSQL for platform, orchestrator, web UI, and standalone agent session state
- SeaweedFS exposed through an S3-compatible endpoint for artifacts
- live Solace broker credentials from Kubernetes secrets
- live LiteLLM endpoint/model/key from Kubernetes secrets
- one service account and RBAC contract shared by core and standalone agents
- standalone Helm releases with generated values files

## 2. Live k8s1 contracts

These are the important runtime targets currently in use on `emeak8s1`.

### 2.1 Core persistence and artifact services

- Core PostgreSQL service: `agent-mesh-postgresql:5432`
- Core SeaweedFS S3 endpoint: `http://agent-mesh-seaweedfs:8333`
- Core namespace/bucket id: `solace-agent-mesh-no-auth`

From live `agent-mesh-persistence`:

- `PLATFORM_DATABASE_URL=postgresql+psycopg2://<redacted>@agent-mesh-postgresql:5432/solace-agent-mesh-no-auth_platform`
- `ORCHESTRATOR_DATABASE_URL=postgresql+psycopg2://<redacted>@agent-mesh-postgresql:5432/solace-agent-mesh-no-auth_orchestrator`
- `WEB_UI_GATEWAY_DATABASE_URL=postgresql+psycopg2://<redacted>@agent-mesh-postgresql:5432/solace-agent-mesh-no-auth_webui`
- `ORCHESTRATOR_SESSION_SERVICE_TYPE=sql`
- `WEB_UI_SESSION_SERVICE_TYPE=sql`
- `S3_ENDPOINT_URL=http://agent-mesh-seaweedfs:8333`
- `S3_BUCKET_NAME=solace-agent-mesh-no-auth`
- `CONNECTOR_SPEC_BUCKET_NAME=solace-agent-mesh-no-auth-connector-specs`
- `AWS_REGION=us-east-1`

### 2.2 Core runtime environment

From live `agent-mesh-environment`, the core stack is driven by env vars for:

- Solace broker: `SOLACE_BROKER_URL`, `SOLACE_BROKER_USERNAME`, `SOLACE_BROKER_PASSWORD`, `SOLACE_BROKER_VPN`, `USE_TEMPORARY_QUEUES`
- LLM routing: `LLM_SERVICE_ENDPOINT`, `LLM_SERVICE_API_KEY`, `LLM_SERVICE_GENERAL_MODEL_NAME`, `LLM_SERVICE_PLANNING_MODEL_NAME`
- UI/platform routing: `FRONTEND_SERVER_URL`, `PLATFORM_SERVICE_URL`, `WEBUI_FRONTEND_SERVER_URL`, `WEBUI_FRONTEND_URL`
- UI auth/CORS: `CORS_ALLOWED_ORIGIN_REGEX`, `FRONTEND_USE_AUTHORIZATION`, `EXTERNAL_AUTH_SERVICE_URL`, `SESSION_SECRET_KEY`

### 2.3 Shared service account

Both core and standalone releases use:

- `serviceAccount.name: solace-agent-mesh-sa`

## 3. Core chart changes from source-style defaults

The source configs use defaults that are good for local/demo startup, but not for k8s1.

### 3.1 Artifact service

Source default in [`custom-joule-agent/configs/shared_config.yaml`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/packages/custom-joule-agent/configs/shared_config.yaml):

```yaml
artifact_service:
  type: "filesystem"
  base_path: "/tmp/samv2"
  artifact_scope: namespace
```

Required k8s1 target:

```yaml
artifact_service:
  type: ${ARTIFACT_SERVICE_TYPE, s3}
  bucket_name: ${S3_BUCKET_NAME}
  endpoint_url: ${S3_ENDPOINT_URL}
  aws_region: ${AWS_REGION, us-east-1}
  artifact_scope: namespace
```

Reason:

- multiple pods must share artifacts
- orchestrator and peer agents must be able to resolve shared files
- SeaweedFS is the shared object store on k8s1

### 3.2 Session/database persistence

Source defaults include:

- platform fallback: `sqlite:///platform.db`
- web UI fallback: `sqlite:///webui_gateway.db`
- shared session service default: `memory`

Required k8s1 target:

- platform -> `PLATFORM_DATABASE_URL`
- orchestrator -> `ORCHESTRATOR_DATABASE_URL`
- web UI -> `WEB_UI_GATEWAY_DATABASE_URL`
- standalone agents -> per-agent `DATABASE_URL`
- session service type -> `sql`

Reason:

- pods are restartable/replaceable on k8s
- orchestration state, sessions, and UI state must survive pod restarts
- local SQLite and in-memory state break shared/runtime continuity

### 3.3 Core chart persistence components

The live `agent-mesh` Helm release includes bundled persistence components that the source YAMLs alone do not create:

- bundled PostgreSQL with `10Gi` PVC
- bundled SeaweedFS with `20Gi` PVC

Observed live settings from `helm get values agent-mesh -n default -a`:

- `postgresql.persistence.size: 10Gi`
- `seaweedfs.persistence.size: 20Gi`
- `seaweedfs.service.ports.s3: 8333`
- `seaweedfs.service.ports.master: 9333`

Implication:

- if you only carry over app YAML and skip the Helm values/secret wiring, the apps will still point to local fallbacks and will not use the cluster persistence stack

### 3.4 Service exposure

Live core chart settings also differ from local defaults:

- `service.type: LoadBalancer`
- service account fixed to `solace-agent-mesh-sa`
- core image is enterprise image `gcr.io/gcp-maas-prod/solace-agent-mesh-enterprise:1.65.45`

This is part of the cluster contract and must be preserved if reproducing the live setup.

## 4. Standalone agent changes required on k8s1

For any standalone agent converted from source/open-source YAML to k8s1, there are two layers of required changes:

1. App config changes inside `config.yaml`
2. Helm `values.yaml` changes for the standalone `sam-agent` chart

### 4.1 Required standalone Helm values contract

Every standalone release on k8s1 follows this pattern:

```yaml
deploymentMode: standalone
id: <release-name>

global:
  persistence:
    namespaceId: 'solace-agent-mesh-no-auth'

serviceAccount:
  name: solace-agent-mesh-sa

image:
  repository: <custom-image>
  tag: <image-tag>
  pullPolicy: IfNotPresent

solaceBroker:
  url: <live broker url>
  username: <live broker username>
  password: <live broker password>
  vpn: <live vpn>
  useTemporaryQueues: true

llmService:
  generalModelName: <live model>
  endpoint: <live LiteLLM endpoint>
  apiKey: <live LiteLLM key>

persistence:
  existingSecrets:
    database: <agent-db-bridge-secret>
    s3: ''

  s3:
    endpointUrl: 'http://agent-mesh-seaweedfs:8333'
    bucketName: 'solace-agent-mesh-no-auth'
    accessKey: <bucket access key>
    secretKey: <bucket secret key>
    region: 'us-east-1'
```

See generated examples:

- [`deploy/rfq/quote-planning-agent-values.generated.yaml`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/deploy/rfq/quote-planning-agent-values.generated.yaml)
- [`deploy/rfq/acme-retail-pim-values.generated.yaml`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/deploy/rfq/acme-retail-pim-values.generated.yaml)
- [`deploy/rfq/sap-joule-agent-values.generated.yaml`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/deploy/rfq/sap-joule-agent-values.generated.yaml)
- [`deploy/rfq/shipping-agent-values.generated.yaml`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/deploy/rfq/shipping-agent-values.generated.yaml)

### 4.2 Required DB bridge secret

Each standalone agent needs a dedicated bridge secret with:

- `DATABASE_URL`
- `PGHOST`
- `PGPORT`
- `PGUSER`
- `PGPASSWORD`

On this repo, that is generated by [`scripts/04_create_db_bridge_secret.sh`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/scripts/04_create_db_bridge_secret.sh).

Reason:

- standalone `sam-agent` deploys expect the DB bootstrap/init path to have those keys available
- this is the compatibility bridge between the upstream chart expectations and the live cluster persistence model

## 5. Source app config to k8s1 app config deltas

This is the app-level YAML translation.

### 5.1 Quote planning agent

Source:

- [`custom-joule-agent/configs/agents/agentic-quote-planning.yaml`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/packages/custom-joule-agent/configs/agents/agentic-quote-planning.yaml)

Deployed:

- [`deploy/rfq/quote-planning-agent-config.yaml`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/deploy/rfq/quote-planning-agent-config.yaml)

Required changes:

- remove `!include ../shared_config.yaml` dependency and inline the needed broker/model blocks
- switch `supports_streaming: true` -> `false` for the deployed standalone behavior used here
- switch session persistence from `ORCHESTRATOR_DATABASE_URL` anchor usage to standalone `DATABASE_URL`
- switch artifact service from filesystem anchor to S3/Seaweed env wiring
- update inter-agent allow list to real deployed peer names:
  - `AcmeRetailPim`
  - `SapJouleAgent`
  - `ShippingAgent`
  - `bedrock_legal_agent`
- harden the instruction so the orchestrator must call all required peers before finalizing

### 5.2 Acme Retail PIM

Source:

- [`custom-joule-agent/configs/agents/acme-retail-pim.yaml`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/packages/custom-joule-agent/configs/agents/acme-retail-pim.yaml)

Deployed:

- [`deploy/rfq/acme-retail-pim-config.yaml`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/deploy/rfq/acme-retail-pim-config.yaml)

Required changes:

- replace shared-config anchors with standalone-friendly inline blocks
- switch session service from local fallback database to standalone `DATABASE_URL`
- switch artifact service from filesystem to Seaweed/S3
- set DB init to explicit PostgreSQL env contract:
  - `ACME_RETAIL_PIM_DB_TYPE=postgresql`
  - `ACME_RETAIL_PIM_DB_HOST`
  - `ACME_RETAIL_PIM_DB_PORT`
  - `ACME_RETAIL_PIM_DB_USER`
  - `ACME_RETAIL_PIM_DB_PASSWORD`
  - `ACME_RETAIL_PIM_DB_NAME`
- disable `auto_detect_schema`
- add explicit `database_schema_override` and `schema_summary_override`

Reason:

- the deployed RFQ PIM uses a dedicated PostgreSQL database
- explicit schema override is more reliable than runtime schema autodetection in this environment

### 5.3 SAP Joule agent

Source:

- [`custom-joule-agent/configs/agents/sap-joule-agent.yaml`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/packages/custom-joule-agent/configs/agents/sap-joule-agent.yaml)

Deployed:

- [`deploy/rfq/sap-joule-agent-config.yaml`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/deploy/rfq/sap-joule-agent-config.yaml)

Required changes:

- remove inline hardcoded SAP URLs/IDs/client secret from YAML
- replace them with env-driven secret-backed config:
  - `SAP_TOKEN_URL`
  - `SAP_BASE_URL`
  - `SAP_AGENT_ID`
  - `SAP_CLIENT_ID`
  - `SAP_CLIENT_SECRET`
  - `SAP_REQUEST_TIMEOUT`
  - `SAP_SSL_VERIFY`
- switch session service to standalone `DATABASE_URL`
- switch artifact service to Seaweed/S3
- normalize `component_module` and `component_base_path` for the packaged image layout

Reason:

- credentials and endpoints must live in Kubernetes secrets, not git-tracked config
- the agent must be restart-safe and artifact-compatible with the rest of the mesh

### 5.4 Shipping agent

Source:

- [`custom-joule-agent/configs/agents/shipping-agent.yaml`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/packages/custom-joule-agent/configs/agents/shipping-agent.yaml)

Deployed:

- [`deploy/rfq/shipping-agent-config.yaml`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/deploy/rfq/shipping-agent-config.yaml)

Required changes:

- remove inline test/demo ShipEngine API key from YAML
- replace with env-driven secret-backed config:
  - `SHIPENGINE_API_KEY`
  - `SHIPENGINE_CARRIER_ID_1..4`
  - `SHIP_FROM_NAME`
  - `SHIP_FROM_PHONE`
  - `SHIP_FROM_COMPANY_NAME`
  - `SHIP_FROM_RESIDENTIAL_INDICATOR`
- switch session service to standalone `DATABASE_URL`
- switch artifact service to Seaweed/S3
- switch from local/demo defaults to real clusterized runtime behavior

## 6. Dedicated RFQ PostgreSQL changes

The core SAM stack uses `agent-mesh-postgresql`, but the RFQ stack was intentionally moved to a separate PostgreSQL release:

- service: `rfq-postgresql:5432`
- Helm release: `rfq-postgresql`

That work is encoded in [`scripts/10_replace_rfq_stack.sh`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/scripts/10_replace_rfq_stack.sh).

Required additions for the RFQ stack were:

- deploy a dedicated PostgreSQL release
- create DB roles/users for:
  - `rfq_quote_planning`
  - `rfq_sap_joule`
  - `rfq_shipping`
  - `rfq_acme_pim`
- create one per-agent DB bridge secret
- seed the PIM schema/data into `rfq_acme_pim`
- create `acme-retail-pim-db-config` secret for SQL agent initialization

This is not present in the source YAML alone. It is a deployment-time k8s1 adaptation.

## 7. Secret contracts that must exist on k8s1

To reproduce the live behavior, the following secret groups must exist.

### 7.1 Core shared secrets

- `agent-mesh-environment`
- `agent-mesh-persistence`
- `agent-mesh-postgresql`

### 7.2 RFQ/runtime-specific secrets

- `sap-joule-credentials`
- `shipping-agent-credentials`
- `acme-retail-pim-db-config`
- `quote-planning-agent-db-bridge`
- `sap-joule-agent-db-bridge`
- `shipping-agent-db-bridge`
- `acme-retail-pim-db-bridge`
- `bedrock-legal-agent-db-bridge`

### 7.3 Why this matters

The source/open-source YAMLs in this repo are not self-sufficient for k8s1 because the real deployment contract is split across:

- app config YAML
- Helm values YAML
- Kubernetes secrets
- packaged image layout

## 8. Minimal translation recipe for any new open-source agent

If you take a new source-style agent config and want it to behave like the current k8s1 stack, apply this checklist.

1. Replace local/shared defaults.
   - remove filesystem artifact storage
   - remove memory session service
   - remove SQLite fallbacks

2. Rebind persistence.
   - session service -> `type: sql`
   - database URL -> `${DATABASE_URL}` for standalone agents
   - artifact service -> S3/Seaweed env vars

3. Rebind runtime dependencies.
   - broker -> `${SOLACE_BROKER_*}`
   - model -> `${LLM_SERVICE_*}`

4. Remove inline credentials.
   - move all API keys, client secrets, endpoints, and DB credentials into Kubernetes secrets

5. Generate standalone Helm values.
   - `deploymentMode: standalone`
   - `global.persistence.namespaceId`
   - `serviceAccount.name`
   - `solaceBroker.*`
   - `llmService.*`
   - `persistence.existingSecrets.database`
   - `persistence.s3.*`

6. Create DB bridge secret.
   - one per standalone agent

7. Package the image correctly.
   - ensure Python modules referenced by `component_module` are actually installed into the runtime image

8. Verify in-cluster names.
   - service names
   - peer agent names in inter-agent allow lists
   - secret names
   - DB service hostnames

## 9. Files that already encode the k8s1 translation

These files are the current best references for the k8s1-adapted pattern:

- core inventory:
  - [`k8s1-runtime-inventory.md`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/docs/reference/k8s1-runtime-inventory.md)
- standalone bridge/value generation:
  - [`scripts/04_create_db_bridge_secret.sh`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/scripts/04_create_db_bridge_secret.sh)
- RFQ stack replacement/deployment:
  - [`scripts/10_replace_rfq_stack.sh`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/scripts/10_replace_rfq_stack.sh)
- deployed standalone configs:
  - [`deploy/rfq/quote-planning-agent-config.yaml`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/deploy/rfq/quote-planning-agent-config.yaml)
  - [`deploy/rfq/acme-retail-pim-config.yaml`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/deploy/rfq/acme-retail-pim-config.yaml)
  - [`deploy/rfq/sap-joule-agent-config.yaml`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/deploy/rfq/sap-joule-agent-config.yaml)
  - [`deploy/rfq/shipping-agent-config.yaml`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/deploy/rfq/shipping-agent-config.yaml)
- generated standalone values:
  - [`deploy/rfq/quote-planning-agent-values.generated.yaml`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/deploy/rfq/quote-planning-agent-values.generated.yaml)
  - [`deploy/rfq/acme-retail-pim-values.generated.yaml`](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/deploy/rfq/acme-retail-pim-values.generated.yaml)

## 10. Bottom line

The main required migration is:

- filesystem -> SeaweedFS/S3
- SQLite/memory -> PostgreSQL/SQL
- inline creds -> Kubernetes secrets
- source YAML only -> source YAML + generated standalone Helm values + DB bridge secret + packaged image

Without those changes, the open-source/source-style configs will start, but they will not behave like the current shared k8s1 deployment.
