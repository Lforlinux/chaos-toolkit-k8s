#!/bin/bash

# Sanity Test Deployment Script
# This script deploys the sanity test application to check health endpoints of all microservices

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Sanity Test Deployment Script ===${NC}"
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
REQUIRED_FILES=("namespace.yaml" "configmap.yaml" "deployment.yaml" "service.yaml")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "${SCRIPT_DIR}/${file}" ]; then
        echo -e "${RED}Error: ${file} not found in ${SCRIPT_DIR}${NC}"
        exit 1
    fi
done

echo -e "${YELLOW}Step 1: Creating sanity-test namespace...${NC}"
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

echo -e "${YELLOW}Step 4: Deploying Service...${NC}"
kubectl apply -f "${SCRIPT_DIR}/service.yaml"
echo -e "${GREEN}✓ Service deployed${NC}"
echo ""

echo -e "${YELLOW}Step 5: Waiting for sanity-test to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/sanity-test-app -n sanity-test || {
    echo -e "${RED}Error: Sanity test deployment did not become ready within 5 minutes${NC}"
    echo "Check pod status with: kubectl get pods -n sanity-test"
    exit 1
}
echo -e "${GREEN}✓ Sanity test is ready${NC}"
echo ""

echo -e "${YELLOW}Step 6: Verifying deployment...${NC}"
SANITY_POD=$(kubectl get pods -n sanity-test -l app=sanity-test-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$SANITY_POD" ]; then
    echo -e "${RED}Error: Sanity test pod not found${NC}"
    exit 1
fi

# Check if pod is running
POD_STATUS=$(kubectl get pod "$SANITY_POD" -n sanity-test -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$POD_STATUS" != "Running" ]; then
    echo -e "${YELLOW}Warning: Sanity test pod status is ${POD_STATUS}${NC}"
    echo "Pod details:"
    kubectl describe pod "$SANITY_POD" -n sanity-test | tail -20
else
    echo -e "${GREEN}✓ Sanity test pod is Running${NC}"
fi

# Check if services exist
if kubectl get svc sanity-test-app -n sanity-test &> /dev/null; then
    echo -e "${GREEN}✓ Sanity test ClusterIP service is available${NC}"
    kubectl get svc sanity-test-app -n sanity-test
fi

if kubectl get svc sanity-test-external -n sanity-test &> /dev/null; then
    echo -e "${GREEN}✓ Sanity test LoadBalancer service is available${NC}"
    EXTERNAL_IP=$(kubectl get svc sanity-test-external -n sanity-test -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")
    if [ "$EXTERNAL_IP" != "pending" ] && [ -n "$EXTERNAL_IP" ]; then
        echo "  External URL: http://${EXTERNAL_IP}"
    else
        echo "  External IP: pending (may take a few minutes)"
    fi
fi

# Test application
echo ""
echo -e "${YELLOW}Step 7: Testing application...${NC}"
sleep 3
if kubectl exec -n sanity-test deployment/sanity-test-app -- wget -qO- http://localhost:5000/health 2>/dev/null | grep -q "ok"; then
    echo -e "${GREEN}✓ Application is responding${NC}"
else
    echo -e "${YELLOW}Warning: Could not verify application health endpoint${NC}"
fi

echo ""
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo ""
echo "Sanity test application is deployed and ready!"
echo ""
echo "What it does:"
echo "  - Checks health endpoints of all microservices in online-boutique namespace"
echo "  - Tests: adservice, cartservice, checkoutservice, currencyservice, emailservice,"
echo "           frontend, paymentservice, productcatalogservice, recommendationservice,"
echo "           shippingservice, redis-cart"
echo ""
echo "Access the application:"
echo "  - Internal: http://sanity-test-app.sanity-test.svc.cluster.local:5000"
echo "  - Port-forward: kubectl port-forward -n sanity-test svc/sanity-test-app 5000:5000"
if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "pending" ]; then
    echo "  - External: http://${EXTERNAL_IP}"
fi
echo ""
echo "View test results:"
echo "  - Dashboard: http://localhost:5000 (after port-forward)"
echo "  - API: curl http://localhost:5000/api/health"
echo ""
echo "Next steps:"
echo "  1. Port-forward to access UI: kubectl port-forward -n sanity-test svc/sanity-test-app 5000:5000"
echo "  2. Open browser: http://localhost:5000"
echo "  3. View health check results for all microservices"
echo ""

