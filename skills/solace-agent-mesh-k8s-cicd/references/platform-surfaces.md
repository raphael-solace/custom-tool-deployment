# Platform Surfaces

This file defines the main control surfaces in a Solace Agent Mesh Kubernetes deployment. Most mistakes happen when a change is applied to the wrong surface.

## 1. Core SAM control plane
Typical chart: `solace-agent-mesh`

Owns:
- Web UI
- platform API
- orchestrator
- auth service
- deployer integration
- shared persistence wiring
- shared artifact store wiring
- shared broker and LLM environment

Usually changed when:
- upgrading SAM version
- changing shared persistence or artifact storage
- changing shared broker or LLM endpoints
- changing auth mode or CORS
- fixing deployer health / namespace wiring

## 2. Gateway releases
Typical chart: `sam-agent` in deployer or standalone mode

Owns:
- event ingestion or event-mesh bridge logic
- event subscriptions and handler rules
- output handlers
- gateway card publishing
- gateway-specific authorization and embed/artifact behavior

Usually changed when:
- subscriptions or event routes change
- target agent changes
- gateway handler expressions change
- gateway runtime version changes

## 3. Standalone agents
Typical chart: `sam-agent`

Owns:
- agent identity and display name
- instructions and model settings
- built-in or Python tool wiring
- peer allow-lists and routing rules
- session persistence for that agent
- any agent-specific env vars and secrets

Usually changed when:
- instruction/prompt changes
- tools change
- Python code changes
- peer names or workflow routing changes
- per-agent DB or external API contracts change

## 4. Custom tool package / image
Owns:
- Python source under `src/`
- package metadata (`pyproject.toml`, wheels, vendored modules)
- Dockerfile and base image
- runtime dependencies for Python tools or plugins

Usually changed when:
- implementing or fixing custom tools
- adding third-party libraries
- adding plugins
- changing the base SAM image

Rule: if this surface changes, rebuild and retag the image.

## 5. Helm values
Owns deployment-time cluster wiring:
- image repository/tag/pull policy
- service account and RBAC references
- broker, LLM, S3, and database secret references
- namespace ID / persistence wiring
- service type, ingress, resources, affinity, tolerations
- deployer-vs-standalone mode

Usually changed when:
- chart inputs change
- image tag changes
- external service wiring changes
- resources or exposure change

Rule: treat values files as environment-specific deployment contracts, not as source code.

## 6. Secrets and secret contracts
Owns real credentials and connection details:
- broker credentials
- database URLs or host/user/password tuples
- S3 credentials
- LLM API keys
- external API tokens

Usually changed when:
- rotating credentials
- moving between environments
- adding a tool that needs a new external secret

Rule: document secret names and required keys explicitly. Never let agents guess a secret shape from memory if they can inspect the cluster or repo.

## 7. Users, auth, and RBAC
Owns:
- user-to-role mapping
- role-to-scope definitions
- auth provider config
- service account bindings and namespace RBAC

Usually changed when:
- adding or removing users or roles
- enabling enterprise auth or OIDC
- fixing platform authorization errors
- changing service account ownership or namespace permissions

Rule: keep application-level RBAC and Kubernetes RBAC separate in your reasoning. They solve different problems.

## 8. Platform API seed data
Owns:
- projects
- prompt library entries
- default agent selection
- sometimes gateway or agent records, depending on the operating model

Usually changed when:
- adding demo scenarios
- updating project prompts
- patching prompt library content
- migrating platform-level objects between environments

Rule: version the seed data in Git and make the API sync idempotent.

## 9. Persistence model
There are two broad persistence patterns:
- bundled persistence inside the chart (for example PostgreSQL and SeaweedFS deployed with SAM)
- external persistence (managed PostgreSQL, S3-compatible artifact storage, pre-existing secrets)

This affects:
- values files
- secret names
- readiness assumptions
- rollback strategy

Never assume one model from another environment. Discover it first.
