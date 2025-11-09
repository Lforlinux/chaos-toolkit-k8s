#!/bin/bash

# Enhanced Monitoring Deployment Script
# This deploys Prometheus, Grafana, kube-state-metrics, and node-exporter with comprehensive monitoring

set -e

echo "🚀 Deploying Enhanced Monitoring Stack..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi

print_success "Kubernetes cluster is accessible"

# Check if microservice demo is deployed
if ! kubectl get deployment frontend -n online-boutique &> /dev/null; then
    print_warning "Online Boutique application not found in online-boutique namespace"
    print_status "Deploying Online Boutique application first..."
    
    # Deploy namespace first
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    NAMESPACE_FILE="${SCRIPT_DIR}/../application/online-boutique-namespace.yaml"
    MANIFEST_FILE="${SCRIPT_DIR}/../application/online-boutique-manifest.yaml"
    
    if [ -f "${NAMESPACE_FILE}" ]; then
        print_status "Creating online-boutique namespace..."
        kubectl apply -f "${NAMESPACE_FILE}"
    fi
    
    if [ -f "${MANIFEST_FILE}" ]; then
        print_status "Deploying Online Boutique microservices..."
        kubectl apply -f "${MANIFEST_FILE}"
        print_status "Waiting for Online Boutique to be ready..."
        kubectl wait --for=condition=available --timeout=300s deployment/frontend -n online-boutique
        print_success "Online Boutique application deployed"
    else
        print_error "Manifest file not found: ${MANIFEST_FILE}"
        exit 1
    fi
else
    print_success "Online Boutique application found"
fi

# Deploy monitoring namespace and components
print_status "Deploying monitoring namespace and RBAC..."
kubectl apply -f monitoring/prometheus/prometheus-enhanced.yaml
print_success "Prometheus and RBAC deployed"

print_status "Deploying kube-state-metrics..."
kubectl apply -f monitoring/prometheus/kube-state-metrics.yaml
print_success "kube-state-metrics deployed"

print_status "Deploying node-exporter..."
kubectl apply -f monitoring/prometheus/node-exporter.yaml
print_success "node-exporter deployed"

print_status "Deploying enhanced Grafana with dashboards..."
kubectl apply -f monitoring/grafana/grafana-enhanced.yaml
print_success "Enhanced Grafana deployed"

print_status "Checking for microservice monitoring annotations..."
MONITORING_FILE="${SCRIPT_DIR}/microservice-monitoring.yaml"
if [ -f "${MONITORING_FILE}" ]; then
    kubectl apply -f "${MONITORING_FILE}"
    print_success "Microservice monitoring annotations applied"
else
    print_warning "microservice-monitoring.yaml not found, skipping (monitoring will still work via service discovery)"
fi

# Wait for deployments
print_status "Waiting for monitoring components to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n monitoring
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring
kubectl wait --for=condition=available --timeout=300s deployment/kube-state-metrics -n monitoring

print_success "All monitoring deployments are ready!"

# Wait for DaemonSet
print_status "Waiting for node-exporter DaemonSet to be ready..."
kubectl wait --for=condition=available --timeout=300s daemonset/node-exporter -n monitoring

print_success "All monitoring components are ready!"

# Get LoadBalancer information
echo ""
print_status "=== Access Information ==="
echo ""
kubectl get services -n monitoring

# Get specific LoadBalancer IPs
PROMETHEUS_IP=$(kubectl get service prometheus-external -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Pending")
GRAFANA_IP=$(kubectl get service grafana-external -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Pending")

echo ""
print_status "=== URLs ==="
echo ""
echo "🔍 Prometheus:"
if [ "$PROMETHEUS_IP" != "Pending" ] && [ "$PROMETHEUS_IP" != "" ]; then
    echo "   http://$PROMETHEUS_IP"
else
    echo "   LoadBalancer IP: Pending"
fi

echo ""
echo "📊 Grafana:"
if [ "$GRAFANA_IP" != "Pending" ] && [ "$GRAFANA_IP" != "" ]; then
    echo "   http://$GRAFANA_IP"
else
    echo "   LoadBalancer IP: Pending"
fi
echo ""
echo "   Username: admin"
echo "   Password: admin123"

echo ""
print_status "=== Monitoring Capabilities ==="
echo ""
echo "✅ Kubernetes Cluster Monitoring:"
echo "   - Node metrics (CPU, Memory, Disk, Network)"
echo "   - Pod metrics (CPU, Memory, Network I/O)"
echo "   - Deployment status and replicas"
echo "   - Service health and endpoints"
echo "   - Namespace resource usage"
echo ""
echo "✅ Microservice Application Monitoring:"
echo "   - Individual service health status"
echo "   - Pod resource utilization"
echo "   - Network traffic between services"
echo "   - Container restart counts"
echo "   - Resource requests vs limits"
echo ""
echo "✅ Available Dashboards:"
echo "   - Kubernetes Cluster Overview"
echo "   - Microservice Application Monitoring"
echo "   - Pod Details Monitoring"
echo "   - Node Exporter Metrics"
echo "   - Kube State Metrics"

echo ""
print_status "=== Quick Verification Commands ==="
echo ""
echo "Check Prometheus targets:"
echo "kubectl port-forward -n monitoring svc/prometheus 9090:9090"
echo "Then visit: http://localhost:9090/targets"
echo ""
echo "Check Grafana dashboards:"
echo "kubectl port-forward -n monitoring svc/grafana 3000:3000"
echo "Then visit: http://localhost:3000 (admin/admin123)"
echo ""
echo "Check microservice pods:"
echo "kubectl get pods -n online-boutique -l app=frontend"
echo "kubectl get pods -n online-boutique -l app=emailservice"
echo ""

print_success "🎉 Enhanced monitoring stack deployed successfully!"
echo ""
print_status "Next steps:"
echo "1. Wait for LoadBalancer IPs to be assigned (if using cloud provider)"
echo "2. Access Grafana and explore the pre-configured dashboards"
echo "3. Check Prometheus targets to ensure all services are being scraped"
echo "4. Monitor your microservice application in real-time"
echo ""
print_status "Troubleshooting:"
echo "- If targets are down in Prometheus, check pod logs: kubectl logs -n monitoring deployment/prometheus"
echo "- If dashboards are empty, verify metrics are being collected: kubectl top pods -n online-boutique"
echo "- For LoadBalancer issues, use port-forwarding as shown above"
