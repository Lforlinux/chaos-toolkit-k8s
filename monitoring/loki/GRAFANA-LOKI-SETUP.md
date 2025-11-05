# Grafana Loki Data Source Setup Guide

## Issue: "Unable to connect with Loki (Failed to call resource)"

This happens when the Loki URL is set to `localhost:3100` which doesn't work in Kubernetes.

## Solution

### Option 1: Use Auto-Provisioned Data Source (Recommended)

The Loki data source should be automatically configured via ConfigMap. To verify:

1. **Go to Grafana** → **Configuration** → **Data Sources**
2. Look for **"Loki"** in the list
3. If it exists, click on it and verify the URL is: `http://loki:3100`
4. Click **"Save & Test"** - should show "Data source is working"

### Option 2: Manual Configuration (If Auto-Provisioned Doesn't Work)

If you need to manually add/configure the Loki data source:

1. **Go to Grafana** → **Configuration** → **Data Sources**
2. Click **"Add data source"**
3. Select **"Loki"**
4. **Important**: Set the URL to:
   ```
   http://loki:3100
   ```
   **NOT** `http://localhost:3100`

5. **Access**: Select "Server (default)"
6. Click **"Save & Test"**

### Option 3: Use Full FQDN (If Short Name Doesn't Work)

If `http://loki:3100` doesn't work, try the full FQDN:
```
http://loki.monitoring.svc.cluster.local:3100
```

## Verification

After configuring, test the connection:

1. Go to **Explore** (compass icon)
2. Select **"Loki"** from data source dropdown
3. Try this query:
   ```logql
   {namespace="online-boutique"}
   ```
4. Click **"Run query"**

You should see logs from your microservices.

## Troubleshooting

### Check if Loki is running:
```bash
kubectl get pods -n monitoring | grep loki
kubectl logs -n monitoring deployment/loki --tail=10
```

### Check if Grafana can reach Loki:
```bash
kubectl exec -n monitoring deployment/grafana -- wget -qO- http://loki:3100/ready
# Should output: "ready"
```

### Check ConfigMap:
```bash
kubectl get configmap grafana-datasources -n monitoring -o yaml | grep -A 5 Loki
```

### Restart Grafana to pick up ConfigMap changes:
```bash
kubectl rollout restart deployment grafana -n monitoring
```

## Common Issues

### Issue: "localhost:3100" in URL
**Fix**: Change to `http://loki:3100` (both are in `monitoring` namespace)

### Issue: "Connection refused"
**Fix**: Check if Loki pod is running:
```bash
kubectl get pods -n monitoring | grep loki
```

### Issue: Data source not appearing
**Fix**: Restart Grafana:
```bash
kubectl rollout restart deployment grafana -n monitoring
```

## Quick Test Query

Once configured, try this in Grafana Explore:

```logql
{namespace="online-boutique"} |= "error"
```

This will show all error logs from your microservices.

