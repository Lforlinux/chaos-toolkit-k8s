# Loki Quick Start Guide

## ✅ Deployment Status

Loki stack is now deployed and running!

## 🚀 Quick Access

### Grafana (with Loki data source)
```
http://a5dee8dfe96c74d3ab14dd739db63fcb-1707028299.eu-west-1.elb.amazonaws.com
```

### Loki API (Internal only)
- **Internal**: `http://loki.monitoring.svc.cluster.local:3100`
- **Note**: Loki is API-only (no web UI). Access via Grafana instead.

## 📊 Using Loki in Grafana

### Step 1: Access Grafana
1. Open Grafana UI
2. Login (default: `admin` / `admin123`)
3. Go to **Explore** (compass icon) or **Dashboards** → **New Dashboard**

### Step 2: Select Loki Data Source
- In Explore, select **"Loki"** from the data source dropdown
- You should see the query editor

### Step 3: Try These Queries

#### View all logs from online-boutique namespace:
```logql
{namespace="online-boutique"}
```

#### View error logs:
```logql
{namespace="online-boutique"} |= "error"
```

#### View logs from frontend:
```logql
{namespace="online-boutique", app="frontend"}
```

#### View logs from specific pod:
```logql
{namespace="online-boutique", pod=~"frontend-.*"}
```

## 📈 Import Loki Dashboard

1. Go to **Dashboards** → **Import**
2. Enter Dashboard ID: **`15141`** (Loki & Promtail)
3. Click **Load**
4. Select **Loki** data source
5. Click **Import**

## 🔍 Useful LogQL Queries

### All microservices logs
```logql
{namespace="online-boutique"}
```

### Errors only
```logql
{namespace="online-boutique"} |= "error" | json
```

### Frontend logs
```logql
{namespace="online-boutique", app="frontend"}
```

### Logs from last hour
```logql
{namespace="online-boutique"} [1h]
```

### Count logs by pod
```logql
count by (pod) ({namespace="online-boutique"})
```

### Logs containing specific text
```logql
{namespace="online-boutique"} |~ "payment|checkout"
```

## 🎯 Next Steps

1. **Import Loki Dashboard**: Use ID `15141`
2. **Create custom dashboards** for your microservices
3. **Set up alerts** for error patterns
4. **Explore logs** in Grafana Explore view

## 📝 Components

- **Loki**: Running in `monitoring` namespace
- **Promtail**: Running as DaemonSet on all nodes
- **Grafana**: Loki data source configured automatically

## 🔧 Troubleshooting

### Check if Loki is collecting logs:
```bash
kubectl logs -n monitoring deployment/loki --tail=20
```

### Check Promtail:
```bash
kubectl logs -n monitoring daemonset/promtail --tail=20
```

### Test Loki API:
```bash
kubectl port-forward -n monitoring svc/loki 3100:3100
curl http://localhost:3100/ready
```

Happy logging! 🎉

