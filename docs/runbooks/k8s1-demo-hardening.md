# K8S1 Demo Hardening

## Goal
Reduce avoidable demo downtime on `k8s1` by making the known fixes persistent and automatically re-applied after reboot or drift.

## Important limitation
`k8s1` is a single-node k3s cluster. It cannot provide true high availability or a real high-SLA architecture. A node outage, host reboot issue, disk failure, or control-plane failure still takes the environment down.

This hardening only improves:
- clean restart behavior
- recovery from known configuration drift
- automatic self-healing of the SAM demo path

## Problems this hardening covers
1. `agent-mesh-core` regains a stale `webui-index-override` mount and serves broken asset paths.
2. `agent-mesh-agent-deployer` loses the expected `NAMESPACE` and the UI shows `Deployment is unavailable`.
3. `sam-joule` service or path-proxy config drifts from the known-good configuration.
4. The stack comes back after reboot, but the demo path is unhealthy until somebody manually patches it.

## Repo-side fixes
- `deploy/hardening/agent-mesh-core-sam-joule-patch.yaml`
  - keeps the `sam-joule-path-proxy` sidecar
  - no longer reintroduces the stale `webui-index-override` mount
- `deploy/hardening/sam-joule-service.yaml`
  - sanitized `sam-joule` MetalLB service manifest
- `deploy/hardening/sam-joule-path-proxy-config.yaml`
  - sanitized path-proxy ConfigMap

## Host-side hardening installed on `k8s1`
Files installed:
- `/usr/local/bin/k8s1-sam-selfheal.sh`
- `/etc/systemd/system/k8s1-sam-selfheal.service`
- `/etc/systemd/system/k8s1-sam-selfheal.timer`
- `/opt/sam-demo-hardening/*`

Behavior:
- runs once at boot after `k3s`
- runs every 5 minutes after that
- re-applies known-good `sam-joule` service and proxy config
- ensures the deployer namespace is `solace-agent-mesh-no-auth`
- removes any stale `webui-index-override` mount from `agent-mesh-core`
- verifies:
  - UI root serves current `/assets/...` bundles
  - platform health is `healthy`
  - deployer status is `online`
- restarts `agent-mesh-core` or `agent-mesh-agent-deployer` if checks fail

## Install / reapply
```bash
./scripts/22_harden_k8s1_demo.sh
```

## Verify
```bash
ssh rcaillon@192.168.31.57
sudo systemctl status k8s1-sam-selfheal.timer
sudo systemctl status k8s1-sam-selfheal.service
curl -s http://192.168.32.100/api/v1/platform/health
curl -s http://192.168.32.100/api/v1/platform/deployers/status
```

## What is still needed for real SLA
If the goal is genuinely high availability rather than best-effort demo resilience, the next step is architectural:
1. move to at least a 3-node k3s/Kubernetes control plane
2. move persistence off-node or replicate it properly
3. externalize PostgreSQL and S3-compatible storage
4. add real monitoring and alerting
5. remove manual drift and keep everything declarative under Helm/GitOps
