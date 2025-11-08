#!/bin/bash

# Grafana Deployment Script
# This script deploys Grafana visualization platform to the monitoring namespace

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRAFANA_FILE="${SCRIPT_DIR}/grafana-enhanced.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Grafana Deployment Script ===${NC}"
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

# Check if Grafana file exists
if [ ! -f "${GRAFANA_FILE}" ]; then
    echo -e "${RED}Error: grafana-enhanced.yaml not found in ${SCRIPT_DIR}${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Deploying Grafana resources...${NC}"
echo "This includes:"
echo "  - ConfigMaps (datasources, dashboard provider, dashboards)"
echo "  - Deployment"
echo "  - Services (ClusterIP and LoadBalancer)"
echo ""

kubectl apply -f "${GRAFANA_FILE}"
echo -e "${GREEN}✓ Resources applied${NC}"
echo ""

echo -e "${YELLOW}Step 2: Waiting for Grafana to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring || {
    echo -e "${RED}Error: Grafana deployment did not become ready within 5 minutes${NC}"
    echo "Check pod status with: kubectl get pods -n monitoring | grep grafana"
    exit 1
}
echo -e "${GREEN}✓ Grafana is ready${NC}"
echo ""

echo -e "${YELLOW}Step 3: Verifying deployment...${NC}"
GRAFANA_POD=$(kubectl get pods -n monitoring -l app=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$GRAFANA_POD" ]; then
    echo -e "${RED}Error: Grafana pod not found${NC}"
    exit 1
fi

# Check if pod is running
POD_STATUS=$(kubectl get pod "$GRAFANA_POD" -n monitoring -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$POD_STATUS" != "Running" ]; then
    echo -e "${YELLOW}Warning: Grafana pod status is ${POD_STATUS}${NC}"
    echo "Pod details:"
    kubectl describe pod "$GRAFANA_POD" -n monitoring | tail -20
else
    echo -e "${GREEN}✓ Grafana pod is Running${NC}"
fi

# Check if services exist
if kubectl get svc grafana -n monitoring &> /dev/null; then
    echo -e "${GREEN}✓ Grafana ClusterIP service is available${NC}"
    kubectl get svc grafana -n monitoring
else
    echo -e "${RED}Error: Grafana ClusterIP service not found${NC}"
    exit 1
fi

if kubectl get svc grafana-external -n monitoring &> /dev/null; then
    echo -e "${GREEN}✓ Grafana LoadBalancer service is available${NC}"
    EXTERNAL_IP=$(kubectl get svc grafana-external -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")
    if [ "$EXTERNAL_IP" != "pending" ] && [ -n "$EXTERNAL_IP" ]; then
        echo "  External URL: http://${EXTERNAL_IP}"
    else
        echo "  External IP: pending (may take a few minutes)"
    fi
fi

# Test Grafana API
echo ""
echo -e "${YELLOW}Step 4: Testing Grafana API...${NC}"
if kubectl exec -n monitoring deployment/grafana -- wget -qO- http://localhost:3000/api/health 2>/dev/null | grep -q "ok"; then
    echo -e "${GREEN}✓ Grafana API is responding${NC}"
else
    echo -e "${YELLOW}Warning: Could not verify Grafana API health${NC}"
fi

# Get admin password
echo ""
echo -e "${YELLOW}Step 5: Retrieving Grafana admin credentials...${NC}"
ADMIN_PASSWORD=$(kubectl get secret -n monitoring grafana -o jsonpath='{.data.admin-password}' 2>/dev/null | base64 -d 2>/dev/null || echo "")
if [ -n "$ADMIN_PASSWORD" ]; then
    echo -e "${GREEN}✓ Admin credentials found${NC}"
    echo "  Username: admin"
    echo "  Password: ${ADMIN_PASSWORD}"
else
    echo -e "${YELLOW}Warning: Could not retrieve admin password from secret${NC}"
    echo "  Default credentials may be set in grafana-enhanced.yaml"
fi

echo ""
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo ""
echo "Grafana is deployed and ready!"
echo ""
echo "Access Grafana:"
echo "  - Internal: http://grafana.monitoring.svc.cluster.local:3000"
echo "  - Port-forward: kubectl port-forward -n monitoring svc/grafana 3000:3000"
if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "pending" ]; then
    echo "  - External: http://${EXTERNAL_IP}"
fi
echo ""
echo "Default credentials:"
echo "  Username: admin"
if [ -n "$ADMIN_PASSWORD" ]; then
    echo "  Password: ${ADMIN_PASSWORD}"
else
    echo "  Password: (check grafana-enhanced.yaml or secret)"
fi
echo ""
echo "Data sources configured:"
echo "  - Prometheus: http://prometheus:9090"
echo "  - Loki: http://loki:3100 (default)"
echo ""
echo "Next steps:"
echo "  1. Access Grafana UI and login"
echo "  2. Verify data sources are configured correctly"
echo "  3. Import dashboards or create custom dashboards"
echo "  4. Import comprehensive dashboard: dashboards/k8s-observability-comprehensive.json"
echo ""

