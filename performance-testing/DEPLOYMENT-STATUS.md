# Deployment Status Check

## Current Configuration Status

### ✅ **statsd-exporter** - **NOT YET DEPLOYED**
- **Manifest**: `performance-testing/k8s-manifest/statsd-exporter.yaml` ✅ Created
- **Kustomization**: Included in `kustomization.yaml` ✅ Configured
- **ArgoCD App**: `argocd/apps/performance-testing-app.yaml` ✅ Configured
- **Status**: Will be deployed when ArgoCD syncs the `performance-testing` app
- **Action Required**: 
  - If ArgoCD is syncing automatically, it will deploy after you commit/push
  - Or manually sync: `argocd app sync performance-testing`

### ✅ **Prometheus** - **CHECK IF DEPLOYED**
- **ArgoCD App**: `argocd/apps/monitoring-app-local.yaml` ✅ Configured
- **Source**: `monitoring/` directory
- **Status**: Should be deployed if `monitoring-stack` app is synced
- **Check Command**: 
  ```bash
  kubectl get pods -n monitoring -l app=prometheus
  kubectl get svc -n monitoring prometheus
  ```

### ✅ **Grafana** - **CHECK IF DEPLOYED**
- **Manifest**: `monitoring/grafana-enhanced.yaml` ✅ Exists
- **ArgoCD App**: Part of `monitoring-app-local.yaml` ✅ Configured
- **Status**: Should be deployed if `monitoring-stack` app is synced
- **Check Command**: 
  ```bash
  kubectl get pods -n monitoring -l app=grafana
  kubectl get svc -n monitoring grafana
  ```

### ❌ **Grafana Dashboard** - **NOT IMPORTED YET**
- **Dashboard File**: `dashboards/k6-performance-testing-dashboard.json` ✅ Created
- **Official Dashboard ID**: `19665` (recommended)
- **Status**: JSON file exists, but needs manual import into Grafana
- **Action Required**: 
  1. Access Grafana UI
  2. Go to Dashboards → Import
  3. Enter Dashboard ID: `19665` OR upload the JSON file
  4. Select Prometheus as data source

## Quick Deployment Check Commands

```bash
# Check statsd-exporter
kubectl get pods -n performance-testing -l app=statsd-exporter
kubectl get svc -n performance-testing statsd-exporter

# Check Prometheus
kubectl get pods -n monitoring -l app=prometheus
kubectl get svc -n monitoring prometheus

# Check Grafana
kubectl get pods -n monitoring -l app=grafana
kubectl get svc -n monitoring grafana

# Check ArgoCD apps
argocd app list
argocd app get performance-testing
argocd app get monitoring-stack
```

## Deployment Steps

### 1. Deploy statsd-exporter (if not deployed)
```bash
# Option A: Via ArgoCD (recommended)
# Just commit and push - ArgoCD will auto-sync
git add .
git commit -m "Add statsd-exporter for k6 Prometheus integration"
git push

# Option B: Manual deployment
kubectl apply -f performance-testing/k8s-manifest/statsd-exporter.yaml
```

### 2. Verify Prometheus is scraping statsd-exporter
```bash
# Port-forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Open http://localhost:9090
# Go to Status → Targets
# Look for statsd-exporter target
```

### 3. Import Grafana Dashboard
1. Access Grafana (port-forward or via LoadBalancer)
2. Go to Dashboards → Import
3. Enter Dashboard ID: `19665`
4. Select Prometheus data source
5. Click Import

## Summary

| Component | Status | Action |
|-----------|--------|--------|
| statsd-exporter manifest | ✅ Created | Deploy via ArgoCD or manually |
| Prometheus | ⚠️ Check | Verify if monitoring-stack is deployed |
| Grafana | ⚠️ Check | Verify if monitoring-stack is deployed |
| Grafana Dashboard | ❌ Not imported | Manual import required |

