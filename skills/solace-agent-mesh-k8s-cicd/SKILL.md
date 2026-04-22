---
name: solace-agent-mesh-k8s-cicd
description: Use when planning, modifying, reviewing, upgrading, or validating Solace Agent Mesh deployments on Kubernetes, including core releases, gateways, standalone agents, RBAC/users, prompts/projects, secrets, persistence, and custom Python tool images.
---

# Solace Agent Mesh k8s CI/CD

## Overview
This skill helps Codex agents make correct, minimally disruptive changes to Solace Agent Mesh on Kubernetes. It is for Git-managed SAM environments that use Helm, Kubernetes secrets/config, and optionally custom Python tool packages baked into images.

Start by discovering the live topology, then classify the change, then edit only the required control surfaces, then dry-run, deploy, verify, and document rollback.

## Quick Start
1. Run `scripts/collect_sam_inventory.sh <namespace> [output-dir]` before making assumptions about release names, pods, services, secrets, or chart mode.
2. Snapshot every release you might touch with `scripts/backup_helm_release.sh <namespace> <release> [output-dir]`.
3. Classify the request into one or more change surfaces:
   - standalone agent
   - gateway
   - SAM core/control plane
   - users/auth/RBAC
   - prompts/projects/platform objects
   - secrets/runtime contracts
   - custom Python tools / image build
4. Read the matching reference files before editing.
5. Prefer `helm upgrade --dry-run` or `helm template` before a live rollout.
6. Verify both Kubernetes health and a functional SAM scenario after the change.

## Non-Negotiable Rules
- Never inline real credentials in YAML. Use placeholders or Kubernetes secrets.
- Keep stable identities stable unless the task is an intentional replacement.
  Stable identities include: Helm release name, `id`, `agent_name`, `gateway_id`, project IDs, and secret names that other components already reference.
- If Python code or dependencies change, build a new image tag. YAML-only changes do not justify reusing a stale image if the container contents changed.
- If only prompt text, instructions, allow-lists, routing rules, or built-in tool wiring changes, prefer config-only redeploy over rebuilding the image.
- Upgrade SAM core first, then gateways, then standalone agents, unless a release note explicitly requires a different order.
- Back up live values and rendered manifests before every upgrade or replacement.
- After any live change, verify one end-to-end task, not just pod readiness.

## Workflow Decision Tree
### 1. Inventory and classify
Run the inventory script first, then answer:
- Is this change in core, a gateway, a standalone agent, RBAC/auth, prompts/projects, or custom tool code?
- Is the deployment Git-managed, platform/deployer-managed, or mixed?
- Is the current deployment using bundled persistence or external services?

Read [`references/platform-surfaces.md`](references/platform-surfaces.md) and [`references/change-matrix.md`](references/change-matrix.md).

### 2. Choose the correct workflow
- New or updated standalone agent: read [`references/deployment-workflows.md`](references/deployment-workflows.md)
- Gateway changes: read [`references/deployment-workflows.md`](references/deployment-workflows.md)
- Core or chart upgrade: read [`references/versioning-and-release-policy.md`](references/versioning-and-release-policy.md)
- RBAC, users, or auth wiring: read [`references/platform-surfaces.md`](references/platform-surfaces.md)
- Prompt library, projects, or platform API objects: read [`references/deployment-workflows.md`](references/deployment-workflows.md)
- Final checks and rollback: read [`references/validation-and-rollback.md`](references/validation-and-rollback.md)

### 3. Make only the required edits
Use the change matrix to decide whether the task requires changes in:
- app `config.yaml`
- Helm values
- secret contract
- image tag / package version
- platform API seed data
- RBAC/auth config

If the request touches multiple surfaces, edit them together and keep the versions aligned.

### 4. Validate before and after rollout
Minimum validation:
- rendered config looks correct
- release dry-run succeeds
- rollout succeeds
- logs show healthy startup
- platform health is green
- target agent/gateway is discoverable
- one real scenario completes

Use [`references/validation-and-rollback.md`](references/validation-and-rollback.md).

## When to Rebuild the Image
Rebuild and retag the image when any of these change:
- Python source under `src/`
- `pyproject.toml`, requirements, or wheel contents
- vendored plugin or tool modules
- base image version

Do not rebuild the image for pure config changes such as:
- instruction or prompt edits
- model endpoint or model-name env references
- allow-lists and peer names
- routing rules
- RBAC changes
- prompt library entries

## When to Change Identity vs Version Only
- Keep the same release name and `id` for in-place upgrades.
- Keep the same `agent_name` or `gateway_id` if downstream peers, projects, or users already reference it.
- Change the identity only when you are intentionally replacing a component or running both old and new side by side.
- Bump image tags for code changes. Bump chart/app config revision in Git for config changes. Use semantic versions or immutable git-SHA tags; do not reuse mutable image tags in production pipelines.

## Scripts
### `scripts/collect_sam_inventory.sh`
Use this first. It inventories namespace state, Helm releases, workloads, services, ingress, config maps, secrets, role bindings, and likely SAM-related releases.

### `scripts/backup_helm_release.sh`
Use this before changing a Helm-managed component. It saves `helm status`, `helm get values`, `helm get manifest`, `kubectl get` outputs, and recent logs for rollback/debugging.

## References
- [`references/platform-surfaces.md`](references/platform-surfaces.md): what each SAM control surface owns
- [`references/change-matrix.md`](references/change-matrix.md): what to edit for each change type
- [`references/deployment-workflows.md`](references/deployment-workflows.md): step-by-step rollout patterns
- [`references/versioning-and-release-policy.md`](references/versioning-and-release-policy.md): versioning rules, upgrade order, and replacement strategy
- [`references/validation-and-rollback.md`](references/validation-and-rollback.md): smoke tests, functional checks, and rollback procedures

## Output Expectations
When using this skill, return:
1. the discovered topology and assumptions
2. the exact change surfaces being modified
3. the files or Kubernetes objects to edit
4. the rollout plan
5. the verification plan
6. the rollback path

If the environment already contains live values, manifests, or runbooks, use them as evidence but do not overfit the final guidance to one cluster unless the task is explicitly cluster-specific.
