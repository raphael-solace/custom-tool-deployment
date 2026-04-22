# Versioning and Release Policy

## 1. Version the right thing
A SAM deployment has multiple versions at once. Keep them separate.

### Source/config version
What changed in Git:
- agent `config.yaml`
- gateway config
- values files
- RBAC/auth config
- prompt/project seed data

Use normal Git history, PRs, and tags here.

### Runtime image version
What is inside the container:
- custom Python tools
- package dependencies
- vendored plugins
- base image version

Use immutable image tags. Good patterns:
- semantic version: `1.4.2`
- git SHA: `sha-<commit>`
- environment stamp plus Git SHA: `prod-20260421-<sha>`

Do not reuse `latest` or mutable local tags in shared environments.

### Chart/release version
What Helm is deploying:
- SAM core chart version
- `sam-agent` chart version
- values schema compatibility

Record chart version and app/image tag together in release notes or PR description.

## 2. How to version an agent YAML
Treat the agent YAML as API-like contract.

### Patch change
Safe behavior-preserving edits:
- clarifying instruction text
- adjusting prompt wording
- bug-fixing route/allow-list mistakes without changing identity
- small built-in tool config fixes

### Minor change
Behavior extension without identity break:
- adding a new tool
- adding a new peer dependency
- changing model defaults
- adding new optional env vars or secret keys

### Major change
Breaking contract change:
- changing `agent_name`
- renaming or deleting tool functions that callers rely on
- changing required input schema or required secret keys
- removing peers or changing expected output schema

If you make a major change, prefer a replacement release or explicit migration notes.

## 3. How to version custom tool packages
- bump package version when Python code or dependencies change
- cut a new image tag for every package change
- update the release values to the new tag
- verify the module import path still matches `component_module`

A common failure mode is `component_module: src.foo.bar`. The import path should be the Python package path, not the filesystem path.

## 4. Upgrade order
### SAM runtime/platform upgrade
1. back up live values and manifests
2. upgrade core
3. verify control plane and deployer health
4. upgrade gateways
5. upgrade standalone agents
6. rerun smoke tests

### Agent-only upgrade
1. back up the release
2. update config and/or image tag
3. dry-run
4. upgrade the release
5. verify logs and one real task

## 5. What must stay aligned
- image tag must match the actual built contents
- values file must reference the right image tag
- secret names in values must exist in cluster
- `agent_name` / `gateway_id` must match peer references and project pointers
- model, broker, DB, and artifact placeholders must map to real env/secret keys

## 6. Skills, prompts, and reusable scenario content
If the environment uses prompt libraries, project templates, or reusable scenarios:
- version them in Git like code
- seed/sync them idempotently
- tie their validation to scenario tests
- treat prompt changes as deployable config changes, not ad hoc UI edits

## 7. Roll-forward vs rollback
Prefer roll-forward for:
- prompt fixes
- routing fixes
- secret reference mistakes
- resource adjustments

Prefer rollback for:
- platform startup failures after a chart upgrade
- incompatible image pushes
- broken auth or broken persistence migrations
- identity changes that disrupted dependencies

Keep rollback commands and old rendered manifests available before any live upgrade.
