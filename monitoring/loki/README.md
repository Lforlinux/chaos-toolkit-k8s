# Loki Stack for Log Aggregation

## Overview

Loki is a horizontally-scalable, highly-available log aggregation system inspired by Prometheus. This deployment includes:

- **Loki**: Log aggregation server
- **Promtail**: Log collector agent (runs as DaemonSet on all nodes)
- **Grafana Integration**: Loki configured as data source in Grafana

## How We Achieved This Setup

### Deployment Approach

#### 1. Loki Deployment (Manual via kubectl)
Loki was deployed manually using Kubernetes manifests:
- **Deployment**: `monitoring/loki/loki-deployment.yaml` - Deploys Loki as a single replica
- **Service**: ClusterIP service exposing port 3100
- **ConfigMap**: `monitoring/loki/loki-config.yaml` - Loki configuration using filesystem storage
- **Storage**: Currently using `emptyDir` (ephemeral) for development

**Deployment command:**
```bash
kubectl apply -f monitoring/loki/loki-deployment.yaml
kubectl apply -f monitoring/loki/loki-config.yaml
```

#### 2. Promtail Deployment (Helm Chart)
After attempting manual Promtail configuration, we switched to the official Grafana Helm chart for better reliability:

**Helm Installation:**
```bash
# Add Grafana Helm repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Promtail
helm install my-promtail grafana/promtail --version 6.17.1 \
  -n monitoring \
  --create-namespace \
  -f monitoring/loki/promtail-values.yaml
```

**Promtail Values Configuration:**
The `monitoring/loki/promtail-values.yaml` file configures:
- Loki service endpoint: `http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push`
- Automatic log collection from all Kubernetes pods
- Proper RBAC permissions for Kubernetes service discovery

**Why Helm for Promtail:**
- Manual Promtail configuration had issues with log path mapping (`/var/log/pods/<namespace>_<pod-name>_<pod-uid>/<container>/*.log`)
- Helm chart handles Kubernetes log path discovery automatically
- Better default configuration and RBAC setup
- Easier maintenance and updates

#### 3. Grafana Integration
Loki data source was configured in Grafana via ConfigMap:
- **ConfigMap**: `monitoring/grafana-enhanced.yaml` (grafana-datasources section)
- **URL**: `http://loki:3100`
- **Set as default datasource**: `isDefault: true`

**Configuration:**
```yaml
- name: Loki
  type: loki
  access: proxy
  url: http://loki:3100
  isDefault: true
  editable: true
  jsonData:
    maxLines: 1000
```

### Challenges Encountered & Solutions

#### Challenge 1: Promtail Not Collecting Logs
**Problem**: Manual Promtail configuration couldn't correctly map Kubernetes log paths. Promtail was discovering pods but not tailing log files.

**Solution**: Switched to Helm chart which handles Kubernetes log path discovery automatically.

#### Challenge 2: Grafana Data Source Connection
**Problem**: Initial setup used `http://localhost:3100` which doesn't work in Kubernetes.

**Solution**: Updated to use service name `http://loki:3100` (same format as Prometheus datasource).

#### Challenge 3: No Labels in Loki
**Problem**: After connecting Grafana to Loki, no labels were showing up.

**Solution**: 
1. Verified Promtail was running and collecting logs
2. Confirmed Promtail could reach Loki service
3. Used Helm chart which properly configures Promtail to collect logs from all pods
4. After Helm installation, labels appeared correctly (namespaces: argocd, availability-test, kube-system, litmus, monitoring, online-boutique, sanity-test)

### Current Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Kubernetes Pods (all namespaces)                      │
│  Logs stored in: /var/log/pods/                        │
└────────────────────┬──────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Promtail (Helm Chart)                                  │
│  - DaemonSet on all nodes                               │
│  - Auto-discovers pods via Kubernetes API               │
│  - Collects logs from /var/log/pods                     │
│  - Sends to Loki via HTTP API                           │
└────────────────────┬──────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Loki (Manual Deployment)                               │
│  - Service: loki.monitoring.svc.cluster.local:3100      │
│  - Storage: emptyDir (ephemeral)                        │
│  - API: /loki/api/v1/*                                 │
└────────────────────┬──────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Grafana                                                │
│  - Loki datasource configured                           │
│  - Default datasource for log queries                   │
│  - Query interface via LogQL                            │
└─────────────────────────────────────────────────────────┘
```

### Verification Steps

After deployment, verify the setup:

1. **Check Loki is running:**
   ```bash
   kubectl get pods -n monitoring | grep loki
   kubectl logs -n monitoring deployment/loki --tail=20
   ```

2. **Check Promtail is running:**
   ```bash
   kubectl get pods -n monitoring -l app.kubernetes.io/name=promtail
   kubectl logs -n monitoring daemonset/my-promtail --tail=20
   ```

3. **Verify Loki has labels:**
   ```bash
   kubectl exec -n monitoring deployment/loki -- \
     wget -qO- "http://localhost:3100/loki/api/v1/labels" | python3 -m json.tool
   ```
   Should show: `["namespace", "pod", "container", ...]`

4. **Test in Grafana:**
   - Go to **Explore** → Select **Loki**
   - Query: `{namespace="online-boutique"}`
   - Should see logs from your microservices

### Files & Configuration

**Loki Files:**
- `monitoring/loki/loki-deployment.yaml` - Loki deployment and service
- `monitoring/loki/loki-config.yaml` - Loki configuration (filesystem storage)

**Promtail Files:**
- `monitoring/loki/promtail-values.yaml` - Helm values for Promtail installation

**Grafana Configuration:**
- `monitoring/grafana-enhanced.yaml` - Contains Loki datasource configuration

**ArgoCD (Optional):**
- `argocd/loki-app.yaml` - ArgoCD application for GitOps deployment

## Architecture

```
Kubernetes Pods → Promtail (DaemonSet) → Loki → Grafana
```

## Components

### 1. Loki
- Aggregates logs from Promtail
- Stores logs in filesystem (can be configured for S3)
- Exposes API on port 3100

### 2. Promtail
- Runs as DaemonSet on all nodes
- Collects logs from `/var/log/pods` and `/var/lib/docker/containers`
- Sends logs to Loki via HTTP API

### 3. Grafana Integration
- Loki automatically added as data source
- Query logs using LogQL (similar to PromQL)

## Deployment

### Via ArgoCD (Recommended)
```bash
kubectl apply -f argocd/loki-app.yaml
```

### Via kubectl (Manual)
```bash
kubectl apply -f monitoring/loki/
```

## Access

### Loki API
- **Internal**: `http://loki.monitoring.svc.cluster.local:3100`
- **Note**: Loki is an API service (no web UI). Access logs through Grafana.
- **For API access**: Use port-forward: `kubectl port-forward -n monitoring svc/loki 3100:3100`

### Grafana
- Loki is automatically configured as a data source
- Access Grafana and use Loki for log queries

## Usage in Grafana

### 1. Explore Logs
- Go to Grafana → Explore
- Select "Loki" data source
- Use LogQL queries (see below)

### 2. Create Log Dashboards
- Create new dashboard
- Add panel → Select "Loki" data source
- Use LogQL queries

## LogQL Queries (Examples)

### View all logs from a namespace
```logql
{namespace="online-boutique"}
```

### View logs from a specific pod
```logql
{namespace="online-boutique", pod="frontend-xxx"}
```

### View logs from a specific container
```logql
{namespace="online-boutique", container="server"}
```

### Filter logs by label and text
```logql
{namespace="online-boutique"} |= "error"
```

### Filter by multiple labels
```logql
{namespace="online-boutique", app="frontend"} |= "error"
```

### Count log lines by pod
```logql
count by (pod) ({namespace="online-boutique"})
```

### Rate of log lines per second
```logql
rate({namespace="online-boutique"}[1m])
```

### Logs from last 5 minutes
```logql
{namespace="online-boutique"} [5m]
```

### Combine with metrics (top 10 pods by log volume)
```logql
topk(10, sum(rate({namespace="online-boutique"}[5m])) by (pod))
```

## Useful Queries for Your Setup

### All microservices logs
```logql
{namespace="online-boutique"}
```

### Frontend errors only
```logql
{namespace="online-boutique", app="frontend"} |= "error" | json
```

### Cart service logs
```logql
{namespace="online-boutique", app="cartservice"}
```

### Availability test logs
```logql
{namespace="availability-test"}
```

### Sanity test logs
```logql
{namespace="sanity-test"}
```

### ArgoCD logs
```logql
{namespace="argocd"}
```

### Monitoring stack logs
```logql
{namespace="monitoring"}
```

## Troubleshooting

### Check Loki status
```bash
kubectl get pods -n monitoring | grep loki
kubectl logs -n monitoring deployment/loki
```

### Check Promtail status
```bash
kubectl get pods -n monitoring | grep promtail
kubectl logs -n monitoring daemonset/promtail
```

### Verify Loki is receiving logs
```bash
# Port forward to Loki
kubectl port-forward -n monitoring svc/loki 3100:3100

# Query API
curl http://localhost:3100/ready
curl http://localhost:3100/metrics
```

### Check Promtail is collecting logs
```bash
kubectl logs -n monitoring daemonset/promtail --tail=50
```

## Storage

Currently using `emptyDir` (ephemeral storage). For production:
- Use PersistentVolume for persistent storage
- Configure S3/object storage for long-term retention
- Set retention policies

## Next Steps

1. **Import Loki Dashboard**: Dashboard ID `15141` - Loki & Promtail
2. **Create custom dashboards** for your microservices
3. **Set up alerts** based on log patterns
4. **Configure retention** for long-term storage

## Dashboard IDs for Loki

- **Loki & Promtail**: `15141`
- **Kubernetes Logs**: `15905`

