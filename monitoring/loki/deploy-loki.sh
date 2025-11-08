#!/bin/bash

# Loki Deployment Script
# This script deploys Loki log aggregation system to the monitoring namespace

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOKI_DIR="${SCRIPT_DIR}/loki"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Loki Deployment Script ===${NC}"
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

echo -e "${YELLOW}Step 1: Creating monitoring namespace (if not exists)...${NC}"
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Namespace ready${NC}"
echo ""

echo -e "${YELLOW}Step 2: Deploying Loki ConfigMap...${NC}"
if [ ! -f "${LOKI_DIR}/loki-config.yaml" ]; then
    echo -e "${RED}Error: loki-config.yaml not found in ${LOKI_DIR}${NC}"
    exit 1
fi
kubectl apply -f "${LOKI_DIR}/loki-config.yaml"
echo -e "${GREEN}✓ ConfigMap deployed${NC}"
echo ""

echo -e "${YELLOW}Step 3: Deploying Loki Deployment and Service...${NC}"
if [ ! -f "${LOKI_DIR}/loki-deployment.yaml" ]; then
    echo -e "${RED}Error: loki-deployment.yaml not found in ${LOKI_DIR}${NC}"
    exit 1
fi
kubectl apply -f "${LOKI_DIR}/loki-deployment.yaml"
echo -e "${GREEN}✓ Deployment and Service deployed${NC}"
echo ""

echo -e "${YELLOW}Step 4: Waiting for Loki to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/loki -n monitoring || {
    echo -e "${RED}Error: Loki deployment did not become ready within 5 minutes${NC}"
    echo "Check pod status with: kubectl get pods -n monitoring | grep loki"
    exit 1
}
echo -e "${GREEN}✓ Loki is ready${NC}"
echo ""

echo -e "${YELLOW}Step 5: Verifying deployment...${NC}"
LOKI_POD=$(kubectl get pods -n monitoring -l app=loki -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$LOKI_POD" ]; then
    echo -e "${RED}Error: Loki pod not found${NC}"
    exit 1
fi

# Check if pod is running
POD_STATUS=$(kubectl get pod "$LOKI_POD" -n monitoring -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$POD_STATUS" != "Running" ]; then
    echo -e "${YELLOW}Warning: Loki pod status is ${POD_STATUS}${NC}"
    echo "Pod details:"
    kubectl describe pod "$LOKI_POD" -n monitoring | tail -20
else
    echo -e "${GREEN}✓ Loki pod is Running${NC}"
fi

# Check if service exists
if kubectl get svc loki -n monitoring &> /dev/null; then
    echo -e "${GREEN}✓ Loki service is available${NC}"
    kubectl get svc loki -n monitoring
else
    echo -e "${RED}Error: Loki service not found${NC}"
    exit 1
fi

# Test Loki readiness endpoint
echo ""
echo -e "${YELLOW}Step 6: Testing Loki API...${NC}"
if kubectl exec -n monitoring deployment/loki -- wget -qO- http://localhost:3100/ready 2>/dev/null | grep -q "ready"; then
    echo -e "${GREEN}✓ Loki API is responding${NC}"
else
    echo -e "${YELLOW}Warning: Could not verify Loki API readiness${NC}"
fi

echo ""
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo ""
echo "Loki is deployed and ready!"
echo ""
echo "Access Loki:"
echo "  - Internal: http://loki.monitoring.svc.cluster.local:3100"
echo "  - Port-forward: kubectl port-forward -n monitoring svc/loki 3100:3100"
echo ""
echo "Next steps:"
echo "  1. Install Promtail via Helm (if not already installed):"
echo "     helm install my-promtail grafana/promtail --version 6.17.1 -n monitoring -f monitoring/loki/promtail-values.yaml"
echo ""
echo "  2. Verify Grafana has Loki datasource configured"
echo ""
echo "  3. Query logs in Grafana Explore with: {namespace=\"online-boutique\"}"
echo ""

