# Change Matrix

Use this matrix to decide what must change for a given request.

| Change request | Edit app config | Edit Helm values | Rebuild image | Secret change | Platform API sync | Notes |
|---|---|---:|---:|---:|---:|---|
| Change agent instruction/prompt | Yes | Usually no | No | No | Sometimes | Reapply agent release; reseed project/prompt library only if the text lives there too |
| Change built-in tool wiring | Yes | Usually no | No | Sometimes | No | Example: add/remove built-in tool blocks, change tool config env placeholders |
| Change Python tool code | No or yes | Yes if image tag changes | Yes | Sometimes | No | Bump package/image version; config only changes if function/module names or env refs change |
| Add Python dependency | No or yes | Yes | Yes | Sometimes | No | Update package metadata and rebuild image |
| Rename `agent_name` or display name | Yes | Sometimes | No | No | Yes | Renaming `agent_name` can break allow-lists, projects, and peer references |
| Change peer allow-list / routing | Yes | No | No | No | Sometimes | Verify all referenced agent names exist exactly |
| Change model endpoint/model name via env | Maybe | Yes or secret only | No | Often | No | Prefer env placeholders in config; actual values live in secrets/values |
| Rotate broker/LLM/API credentials | No | Sometimes | No | Yes | No | Keep secret contract stable where possible |
| Add external API for an agent | Maybe | Maybe | Maybe | Yes | No | Rebuild image only if new Python package/module is needed |
| Change gateway subscriptions or handlers | Yes | Sometimes | No | No | No | Validate event topics and target agent identity |
| Change gateway target agent | Yes | No | No | No | No | Smoke-test actual event path |
| Change service exposure / ingress / LB | No | Yes | No | Sometimes | No | Gateway and core often differ here |
| Add/update users or scopes | No | No | No | No | No | Edit auth/RBAC config, not agent YAML |
| Change service account / RoleBinding | No | Yes or raw manifest | No | No | No | This is Kubernetes RBAC, not platform RBAC |
| Update prompt library entries | No | No | No | No | Yes | Use idempotent API sync or seeded manifests |
| Update project default agent or project prompt | No | No | No | No | Yes | Keep project IDs stable unless intentionally replacing |
| Upgrade standalone agent SAM runtime version | No | Yes | Maybe | No | No | If only base image tag changes and no custom code: values-only; if custom image extends base image: rebuild |
| Upgrade gateway SAM runtime version | No | Yes | Maybe | No | No | Same rule as agents |
| Upgrade SAM core chart/app version | No | Yes | No unless custom image | Maybe | No | Back up live values/manifests first; compare chart schema deltas |
| Move from filesystem/SQLite to SQL/S3 | Yes | Yes | No | Yes | No | This is a deployment contract migration, not a small patch |

## Identity Rules

### Keep stable unless replacing
- Helm release name
- `id`
- `agent_name`
- `gateway_id`
- project IDs
- secret names already referenced by values

### Safe to version aggressively
- image tags
- package versions in `pyproject.toml`
- Git commit SHA or release labels
- generated values files
- prompt library content versions

## Common traps
1. Changing Python code without changing the image tag.
2. Renaming an agent and forgetting peer allow-lists or project default-agent pointers.
3. Rebuilding the image for a config-only change.
4. Editing live ConfigMaps manually and forgetting to reconcile Git.
5. Treating SAM UI authorization errors as Kubernetes RBAC problems, or the reverse.
6. Upgrading core and agents out of order during a major/minor compatibility change.
