# Enhanced Kubernetes Monitoring Stack

This repository contains a comprehensive monitoring solution for Kubernetes clusters with full stats including pods, deployments, network, CPU, and memory details for microservice applications.

## 🚀 Quick Start

Deploy the complete monitoring stack with a single command:

```bash
./deploy-enhanced-monitoring.sh
```

## 📊 What You Get

### Monitoring Components

1. **Prometheus** - Metrics collection and storage
2. **Grafana** - Visualization and dashboards
3. **kube-state-metrics** - Kubernetes object metrics
4. **node-exporter** - Node-level system metrics
5. **Enhanced microservice monitoring** - Application-specific metrics

### Comprehensive Metrics Coverage

#### 🖥️ Node-Level Metrics
- CPU usage and load
- Memory utilization
- Disk I/O and space
- Network traffic
- System processes

#### 🏗️ Kubernetes Object Metrics
- Pod status and health
- Deployment replicas and availability
- Service endpoints
- Namespace resource usage
- Node conditions and capacity

#### 🚀 Microservice Application Metrics
- Individual service health status
- Pod resource utilization (CPU, Memory)
- Network I/O between services
- Container restart counts
- Resource requests vs limits
- Service-to-service communication

## 📁 File Structure

```
├── prometheus-enhanced.yaml          # Enhanced Prometheus with comprehensive scraping
├── grafana-enhanced.yaml             # Grafana with pre-built dashboards
├── kube-state-metrics.yaml           # Kubernetes object metrics exporter
├── node-exporter.yaml                # Node-level metrics exporter
├── microservice-monitoring.yaml      # Monitoring annotations for microservices
├── deploy-enhanced-monitoring.sh     # One-click deployment script
├── k8s-demo.yaml                     # Microservice demo application
└── README-Enhanced-Monitoring.md     # This file
```

## 🎯 Pre-Built Dashboards

### 1. Kubernetes Cluster Overview
- Cluster CPU and Memory usage
- Pod count by namespace
- Node status and health
- Resource utilization trends

### 2. Microservice Application Monitoring
- Service health status
- Pod CPU usage by service
- Pod Memory usage by service
- Network I/O by pod
- Deployment replica status

### 3. Pod Details Monitoring
- Pod status by namespace
- Pod restart counts
- Container resource requests vs limits
- Detailed pod metrics

## 🔧 Configuration Details

### Prometheus Configuration
- **Scrape Interval**: 15 seconds
- **Retention**: 30 days
- **Targets**: 
  - Kubernetes API server
  - All nodes
  - All pods with annotations
  - kube-state-metrics
  - node-exporter
  - Microservice applications

### Grafana Configuration
- **Default Username**: admin
- **Default Password**: admin123
- **Pre-configured Datasource**: Prometheus
- **Auto-provisioned Dashboards**: 3 comprehensive dashboards

### RBAC Permissions
- Full cluster monitoring permissions
- Service account isolation
- Secure token-based authentication

## 🌐 Access URLs

After deployment, access your monitoring stack:

### Prometheus
- **URL**: `http://<LoadBalancer-IP>:9090`
- **Features**: Query interface, targets status, alerting rules

### Grafana
- **URL**: `http://<LoadBalancer-IP>:3000`
- **Username**: admin
- **Password**: admin123
- **Features**: Pre-built dashboards, custom queries, alerting

## 🔍 Monitoring Your Microservice Application

The enhanced monitoring setup automatically discovers and monitors your microservice demo application including:

- **Frontend Service** - Web interface metrics
- **Email Service** - Email processing metrics
- **Checkout Service** - Order processing metrics
- **Recommendation Service** - ML recommendation metrics
- **Payment Service** - Payment processing metrics
- **Product Catalog Service** - Product data metrics
- **Cart Service** - Shopping cart metrics
- **Currency Service** - Currency conversion metrics
- **Shipping Service** - Shipping calculation metrics
- **Ad Service** - Advertisement serving metrics
- **Redis Cart** - Cache performance metrics
- **Load Generator** - Traffic generation metrics

## 📈 Key Metrics to Monitor

### Application Health
```promql
# Service availability
up{job=~"microservice-.*"}

# Pod restart count
kube_pod_container_status_restarts_total{namespace="default"}

# Pod status
kube_pod_status_phase{namespace="default"}
```

### Resource Utilization
```promql
# CPU usage by pod
rate(container_cpu_usage_seconds_total{pod=~".*"}[5m]) * 100

# Memory usage by pod
container_memory_working_set_bytes{pod=~".*"} / 1024 / 1024

# Network I/O
rate(container_network_receive_bytes_total{pod=~".*"}[5m])
rate(container_network_transmit_bytes_total{pod=~".*"}[5m])
```

### Kubernetes Objects
```promql
# Deployment replicas
kube_deployment_status_replicas{namespace="default"}

# Service endpoints
kube_endpoint_address_available{namespace="default"}

# Node conditions
kube_node_status_condition{condition="Ready"}
```

## 🛠️ Troubleshooting

### Common Issues

1. **Prometheus targets are down**
   ```bash
   kubectl logs -n monitoring deployment/prometheus
   kubectl get pods -n monitoring
   ```

2. **Grafana dashboards are empty**
   ```bash
   kubectl port-forward -n monitoring svc/grafana 3000:3000
   # Check datasource configuration in Grafana
   ```

3. **Microservice metrics not appearing**
   ```bash
   kubectl get pods -n default --show-labels
   kubectl describe pod <pod-name> -n default
   ```

4. **LoadBalancer IP not assigned**
   ```bash
   kubectl get services -n monitoring
   # Use port-forwarding as alternative:
   kubectl port-forward -n monitoring svc/prometheus 9090:9090
   kubectl port-forward -n monitoring svc/grafana 3000:3000
   ```

### Verification Commands

```bash
# Check all monitoring components
kubectl get pods -n monitoring

# Check microservice pods
kubectl get pods -n default

# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Visit http://localhost:9090/targets

# Check resource usage
kubectl top pods -n default
kubectl top nodes
```

## 🔄 Updates and Maintenance

### Updating Monitoring Stack
```bash
# Update Prometheus configuration
kubectl apply -f prometheus-enhanced.yaml

# Update Grafana dashboards
kubectl apply -f grafana-enhanced.yaml

# Restart components if needed
kubectl rollout restart deployment/prometheus -n monitoring
kubectl rollout restart deployment/grafana -n monitoring
```

### Scaling Components
```bash
# Scale Prometheus (if needed)
kubectl scale deployment prometheus --replicas=2 -n monitoring

# Scale Grafana (if needed)
kubectl scale deployment grafana --replicas=2 -n monitoring
```

## 📚 Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Kubernetes Monitoring Best Practices](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-usage-monitoring/)
- [Prometheus Query Language (PromQL)](https://prometheus.io/docs/prometheus/latest/querying/basics/)

## 🎉 Success!

You now have a comprehensive monitoring stack that provides:

✅ **Full visibility** into your Kubernetes cluster  
✅ **Real-time metrics** for all microservices  
✅ **Beautiful dashboards** for easy monitoring  
✅ **Alerting capabilities** (can be extended)  
✅ **Historical data** for trend analysis  
✅ **Resource optimization** insights  

Your microservice demo application is now fully monitored with detailed stats on pods, deployments, network, CPU, and memory usage!
