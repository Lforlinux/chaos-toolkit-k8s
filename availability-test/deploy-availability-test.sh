#!/bin/bash

# Availability Test Deployment Script
# This script deploys the availability test application to continuously test microservices

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Availability Test Deployment Script ===${NC}"
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

# Check if required files exist
REQUIRED_FILES=("namespace.yaml" "configmap.yaml" "deployment.yaml")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "${SCRIPT_DIR}/${file}" ]; then
        echo -e "${RED}Error: ${file} not found in ${SCRIPT_DIR}${NC}"
        exit 1
    fi
done

echo -e "${YELLOW}Step 1: Creating availability-test namespace...${NC}"
kubectl apply -f "${SCRIPT_DIR}/namespace.yaml"
echo -e "${GREEN}✓ Namespace ready${NC}"
echo ""

echo -e "${YELLOW}Step 2: Deploying ConfigMap...${NC}"
kubectl apply -f "${SCRIPT_DIR}/configmap.yaml"
echo -e "${GREEN}✓ ConfigMap deployed${NC}"
echo ""

echo -e "${YELLOW}Step 3: Deploying Deployment...${NC}"
kubectl apply -f "${SCRIPT_DIR}/deployment.yaml"
echo -e "${GREEN}✓ Deployment applied${NC}"
echo ""

echo -e "${YELLOW}Step 4: Deploying LoadBalancer Service (if exists)...${NC}"
if [ -f "${SCRIPT_DIR}/loadbalancer.yaml" ]; then
    kubectl apply -f "${SCRIPT_DIR}/loadbalancer.yaml"
    echo -e "${GREEN}✓ LoadBalancer service deployed${NC}"
else
    echo -e "${YELLOW}⚠ LoadBalancer file not found, skipping${NC}"
fi
echo ""

echo -e "${YELLOW}Step 5: Waiting for availability-test to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/availability-test-app -n availability-test || {
    echo -e "${RED}Error: Availability test deployment did not become ready within 5 minutes${NC}"
    echo "Check pod status with: kubectl get pods -n availability-test"
    exit 1
}
echo -e "${GREEN}✓ Availability test is ready${NC}"
echo ""

echo -e "${YELLOW}Step 6: Verifying deployment...${NC}"
AVAILABILITY_POD=$(kubectl get pods -n availability-test -l app=availability-test-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$AVAILABILITY_POD" ]; then
    echo -e "${RED}Error: Availability test pod not found${NC}"
    exit 1
fi

# Check if pod is running
POD_STATUS=$(kubectl get pod "$AVAILABILITY_POD" -n availability-test -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$POD_STATUS" != "Running" ]; then
    echo -e "${YELLOW}Warning: Availability test pod status is ${POD_STATUS}${NC}"
    echo "Pod details:"
    kubectl describe pod "$AVAILABILITY_POD" -n availability-test | tail -20
else
    echo -e "${GREEN}✓ Availability test pod is Running${NC}"
fi

# Check if LoadBalancer exists
if kubectl get svc availability-test-app -n availability-test &> /dev/null; then
    EXTERNAL_IP=$(kubectl get svc availability-test-app -n availability-test -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")
    if [ "$EXTERNAL_IP" != "pending" ] && [ -n "$EXTERNAL_IP" ]; then
        echo -e "${GREEN}✓ LoadBalancer service is available${NC}"
        echo "  External URL: http://${EXTERNAL_IP}"
    else
        echo -e "${YELLOW}⚠ LoadBalancer IP pending (may take a few minutes)${NC}"
    fi
fi

# Test application
echo ""
echo -e "${YELLOW}Step 7: Testing application...${NC}"
sleep 3
if kubectl exec -n availability-test deployment/availability-test-app -- wget -qO- http://localhost:5000/health 2>/dev/null | grep -q "ok"; then
    echo -e "${GREEN}✓ Application is responding${NC}"
else
    echo -e "${YELLOW}Warning: Could not verify application health endpoint${NC}"
fi

echo ""
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo ""
echo "Availability test application is deployed and ready!"
echo ""
echo "What it does:"
echo "  - Continuously tests availability of microservices"
echo "  - Tests: Cart Service and Frontend Service"
echo "  - Runs tests every 5 minutes (300 seconds)"
echo "  - Provides dashboard to view test results and history"
echo ""
echo "Access the application:"
echo "  - Port-forward: kubectl port-forward -n availability-test svc/availability-test-app 5000:5000"
if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "pending" ]; then
    echo "  - External: http://${EXTERNAL_IP}"
fi
echo ""
echo "View test results:"
echo "  - Dashboard: http://localhost:5000 (after port-forward)"
echo "  - Test history and results are displayed in the UI"
echo ""
echo "Configuration:"
echo "  - Test interval: 300 seconds (5 minutes)"
echo "  - Tests: Cart Service and Frontend Service in online-boutique namespace"
echo ""
echo "Next steps:"
echo "  1. Port-forward to access UI: kubectl port-forward -n availability-test svc/availability-test-app 5000:5000"
echo "  2. Open browser: http://localhost:5000"
echo "  3. View test results and monitor service availability"
echo ""

