# Deployment Workflows

## 1. Discovery and backup workflow
Use for every non-trivial task.

1. Inventory the namespace.
   ```bash
   ./skills/solace-agent-mesh-k8s-cicd/scripts/collect_sam_inventory.sh <namespace> [output-dir]
   ```
2. Identify target release names, chart names, and whether the component is core, gateway, or standalone.
3. Back up each release before changing it.
   ```bash
   ./skills/solace-agent-mesh-k8s-cicd/scripts/backup_helm_release.sh <namespace> <release> [output-dir]
   ```
4. If the environment stores live values/manifests in the repo, diff against those too.

## 2. New standalone agent
Use this when creating a brand-new agent release.

### Prepare inputs
- self-contained agent `config.yaml`
- environment-specific values file
- secret contract document or secret templates
- custom Python package and Dockerfile only if `tool_type: python` or a custom plugin is used

### Authoring rules
- flatten local includes/anchors before handing off the final deployable config
- use env placeholders for broker, LLM, DB, artifact store, and external API keys
- keep `agent_name`, `display_name`, release name, image tag, and secret names explicit
- if the agent talks to peers, define the allow-list with exact deployed names

### Deploy
1. Build/publish image only if custom runtime contents changed.
2. Create or update required secrets.
3. Dry-run the Helm release.
4. Install with `helm upgrade -i`.
5. Wait for rollout and inspect logs.
6. Verify that the agent card appears and one scenario succeeds.

## 3. Update existing standalone agent
This is the most common workflow.

### Config-only update
Examples:
- instruction changes
- prompt/routing changes
- peer allow-list changes
- built-in tool config changes

Steps:
1. Back up the release.
2. Edit app config and, if needed, values.
3. Run dry-run/template validation.
4. `helm upgrade` the existing release.
5. Verify rollout, logs, card discovery, and a real task.

### Code update
Examples:
- Python tool logic
- dependency changes
- base image bump for a custom image

Steps:
1. Back up the release.
2. Update package metadata and code.
3. Build and publish a new immutable image tag.
4. Update values to point to the new tag.
5. Dry-run and redeploy.
6. Verify the runtime imports and the scenario path.

## 4. Gateway change
Use when changing subscriptions, handler rules, target agent, output topics, or gateway runtime version.

1. Back up the release.
2. Edit gateway config.
3. If changing the runtime version or custom code, update image tag too.
4. Dry-run and redeploy.
5. Verify:
   - gateway pod is healthy
   - gateway card is present if expected
   - event path reaches the intended target agent
   - errors are published to the correct topic/handler

## 5. Core SAM change or upgrade
Use for control-plane changes, persistence changes, shared broker/LLM changes, or version upgrades.

1. Back up the core release and current namespace inventory.
2. Compare new chart values schema with live values.
3. Preserve existing namespace IDs, service accounts, ingress/service exposure, secret references, and persistence choices unless the task is a deliberate migration.
4. Upgrade core with Helm.
5. Wait for core health and deployer health.
6. Only then upgrade gateways and standalone agents if required.
7. Verify platform endpoints, deployment availability, and at least one agent execution path.

## 6. Users, auth, and RBAC
Use when the request mentions users, scopes, roles, authorization failures, service accounts, or namespace permissions.

### Application-level auth/RBAC
Edit:
- role-to-scope definitions
- user-to-role assignments
- auth provider config

Check for:
- YAML list vs scalar mistakes on `roles`
- wrong config mount paths
- stale containers still using old mounted config

### Kubernetes RBAC
Edit:
- service accounts
- Roles / ClusterRoles
- RoleBindings / ClusterRoleBindings
- Helm values that reference service accounts

Do not mix the two.

## 7. Prompt library and project changes
Use for seeded demo prompts, reusable scenarios, and project defaults.

1. Keep prompt library entries and project templates in Git.
2. Sync with an idempotent API or seeded manifest flow.
3. After sync, verify with platform API, not just UI.
4. Run one scenario per changed prompt/project.

## 8. Replacement or cutover
Use when replacing an old agent stack with new identities.

1. Back up current platform objects and Helm releases.
2. Capture current projects/default-agent settings.
3. Remove old agents cleanly from both platform metadata and Helm.
4. Deploy new agents in dependency order.
5. Update projects to point to new default agents.
6. Run scenario tests before declaring cutover complete.
