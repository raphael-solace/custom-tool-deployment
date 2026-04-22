# Validation and Rollback

## 1. Minimum validation set
For every live change, do all of these unless the task explicitly narrows the scope.

### Kubernetes health
- `kubectl get pods -n <namespace>`
- `kubectl rollout status <workload> -n <namespace>`
- `kubectl describe pod <pod> -n <namespace>` if rollout stalls
- `kubectl logs <pod> -c <container> -n <namespace> --tail=200`

### Helm state
- `helm status <release> -n <namespace>`
- `helm get values <release> -n <namespace> -a`
- `helm get manifest <release> -n <namespace>` when the rendered object needs inspection

### Platform health
Verify the actual control plane endpoints used by the environment:
- Web UI reachable
- platform API healthy
- deployer healthy if platform-driven deploys are expected
- expected agent/gateway cards present

### Functional smoke test
Run one scenario that proves the changed path works. Examples:
- one agent task for a standalone agent change
- one event-in / event-out path for a gateway change
- one project prompt or seeded scenario for prompt-library changes
- one orchestrated task if peer agents or routing changed

Pod readiness alone is not enough.

## 2. Dry-run and render checks
Use at least one of:
```bash
helm template <release> <chart> -n <namespace> -f values.yaml
helm upgrade -i <release> <chart> -n <namespace> -f values.yaml --dry-run
kubectl apply --dry-run=server -f <manifest.yaml>
```

Use `--set-file config.yaml=<path>` when the chart expects the app config as a file input.

## 3. Startup debugging checklist
If a pod starts but is not ready:
1. check init containers first
2. check DB/S3/persistence endpoints
3. check secret refs and env vars
4. check Python import path and missing dependencies if custom tools are involved
5. check auth/RBAC config loads if the failure is UI or authorization related
6. check probe path/port mismatches after upgrades

## 4. Common failure signatures
### `ModuleNotFoundError`
Usually means one of:
- wrong `component_module`
- package not installed into the image
- wrong working directory or package layout

### `401` / `Not authorized`
Classify correctly:
- broker management auth
- broker client auth
- SAM platform auth/scopes
- Kubernetes RBAC

These are different failure domains.

### Startup probe 503
Usually means core started enough to answer probes but not enough to be healthy. Check:
- broker connection
- persistence readiness
- auth initialization
- internal service URLs
- background init failures in logs

### Agents/gateways missing from UI
Check:
- card publishing enabled
- peer namespace alignment
- deployer health
- authorization scopes
- exact agent names and release health

## 5. Rollback patterns
### Helm rollback
```bash
helm history <release> -n <namespace>
helm rollback <release> <revision> -n <namespace>
```
Use for pure Helm-managed regressions.

### Reapply previous values/manifests
If rollback by revision is risky or insufficient:
- use the backup values/manifests captured before the change
- re-run `helm upgrade` with the known-good values

### Prompt/project rollback
- re-seed the previous prompt library or project payload from Git
- confirm via platform API

### Secret rollback
- reapply the previous secret contract or previous secret data source
- restart only the workloads that consume that secret if needed

## 6. What to record in the final output
Always report:
- what changed
- what was not changed
- exact workloads/releases restarted or upgraded
- verification results
- residual risks
- rollback command or artifact location
