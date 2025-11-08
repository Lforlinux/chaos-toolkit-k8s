#!/bin/bash

# Prometheus Deployment Script
# This script deploys Prometheus monitoring system to the monitoring namespace

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMETHEUS_FILE="${SCRIPT_DIR}/prometheus-enhanced.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Prometheus Deployment Script ===${NC}"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed or not in PATH${NC}"
    exit 1
fi

# Check if we can connect to cluster
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
    echo "Please ensure your kubeconfig is configured correctly"
    exit 1
fi

# Check if Prometheus file exists
if [ ! -f "${PROMETHEUS_FILE}" ]; then
    echo -e "${RED}Error: prometheus-enhanced.yaml not found in ${SCRIPT_DIR}${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Deploying Prometheus resources...${NC}"
echo "This includes:"
echo "  - Namespace (monitoring)"
echo "  - ServiceAccount"
echo "  - ClusterRole and ClusterRoleBinding"
echo "  - ConfigMap (Prometheus configuration)"
echo "  - Deployment"
echo "  - Services (ClusterIP and LoadBalancer)"
echo ""

kubectl apply -f "${PROMETHEUS_FILE}"
echo -e "${GREEN}✓ Resources applied${NC}"
echo ""

echo -e "${YELLOW}Step 2: Waiting for Prometheus to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n monitoring || {
    echo -e "${RED}Error: Prometheus deployment did not become ready within 5 minutes${NC}"
    echo "Check pod status with: kubectl get pods -n monitoring | grep prometheus"
    exit 1
}
echo -e "${GREEN}✓ Prometheus is ready${NC}"
echo ""

echo -e "${YELLOW}Step 3: Verifying deployment...${NC}"
PROMETHEUS_POD=$(kubectl get pods -n monitoring -l app=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$PROMETHEUS_POD" ]; then
    echo -e "${RED}Error: Prometheus pod not found${NC}"
    exit 1
fi

# Check if pod is running
POD_STATUS=$(kubectl get pod "$PROMETHEUS_POD" -n monitoring -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$POD_STATUS" != "Running" ]; then
    echo -e "${YELLOW}Warning: Prometheus pod status is ${POD_STATUS}${NC}"
    echo "Pod details:"
    kubectl describe pod "$PROMETHEUS_POD" -n monitoring | tail -20
else
    echo -e "${GREEN}✓ Prometheus pod is Running${NC}"
fi

# Check if services exist
if kubectl get svc prometheus -n monitoring &> /dev/null; then
    echo -e "${GREEN}✓ Prometheus ClusterIP service is available${NC}"
    kubectl get svc prometheus -n monitoring
else
    echo -e "${RED}Error: Prometheus ClusterIP service not found${NC}"
    exit 1
fi

if kubectl get svc prometheus-external -n monitoring &> /dev/null; then
    echo -e "${GREEN}✓ Prometheus LoadBalancer service is available${NC}"
    EXTERNAL_IP=$(kubectl get svc prometheus-external -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")
    if [ "$EXTERNAL_IP" != "pending" ] && [ -n "$EXTERNAL_IP" ]; then
        echo "  External URL: http://${EXTERNAL_IP}"
    else
        echo "  External IP: pending (may take a few minutes)"
    fi
fi

# Test Prometheus readiness
echo ""
echo -e "${YELLOW}Step 4: Testing Prometheus API...${NC}"
if kubectl exec -n monitoring deployment/prometheus -- wget -qO- http://localhost:9090/-/ready 2>/dev/null | grep -q "Prometheus is Ready"; then
    echo -e "${GREEN}✓ Prometheus API is responding${NC}"
else
    echo -e "${YELLOW}Warning: Could not verify Prometheus API readiness${NC}"
fi

echo ""
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo ""
echo "Prometheus is deployed and ready!"
echo ""
echo "Access Prometheus:"
echo "  - Internal: http://prometheus.monitoring.svc.cluster.local:9090"
echo "  - Port-forward: kubectl port-forward -n monitoring svc/prometheus 9090:9090"
if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "pending" ]; then
    echo "  - External: http://${EXTERNAL_IP}"
fi
echo ""
echo "Next steps:"
echo "  1. Deploy Grafana: ./monitoring/deploy-grafana.sh"
echo "  2. Deploy Kube State Metrics (if needed): kubectl apply -f monitoring/kube-state-metrics.yaml"
echo "  3. Deploy Node Exporter (if needed): kubectl apply -f monitoring/node-exporter.yaml"
echo "  4. Access Prometheus UI and verify targets are being scraped"
echo ""

