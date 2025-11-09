#!/bin/bash

# Demo Service Deployment Script
# This script deploys the project dashboard service to the k8s-demo namespace

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Demo Service Deployment Script ===${NC}"
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

# Check if manifest file exists
MANIFEST_FILE="${SCRIPT_DIR}/demo-service-manifest.yml"
if [ ! -f "${MANIFEST_FILE}" ]; then
    echo -e "${RED}Error: demo-service-manifest.yml not found in ${SCRIPT_DIR}${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Deploying all resources from manifest...${NC}"
echo "This includes:"
echo "  - Namespace (k8s-demo)"
echo "  - ConfigMap (application code)"
echo "  - Deployment"
echo "  - Services (ClusterIP and LoadBalancer)"
echo ""

kubectl apply -f "${MANIFEST_FILE}"
echo -e "${GREEN}✓ All resources applied${NC}"
echo ""

echo -e "${YELLOW}Step 4: Waiting for demo-service to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/demo-service -n k8s-demo || {
    echo -e "${RED}Error: Demo service deployment did not become ready within 5 minutes${NC}"
    echo "Check pod status with: kubectl get pods -n k8s-demo"
    exit 1
}
echo -e "${GREEN}✓ Demo service is ready${NC}"
echo ""

echo -e "${YELLOW}Step 5: Verifying deployment...${NC}"
DEMO_POD=$(kubectl get pods -n k8s-demo -l app=demo-service -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$DEMO_POD" ]; then
    echo -e "${RED}Error: Demo service pod not found${NC}"
    exit 1
fi

# Check if pod is running
POD_STATUS=$(kubectl get pod "$DEMO_POD" -n k8s-demo -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$POD_STATUS" != "Running" ]; then
    echo -e "${YELLOW}Warning: Demo service pod status is ${POD_STATUS}${NC}"
    echo "Pod details:"
    kubectl describe pod "$DEMO_POD" -n k8s-demo | tail -20
else
    echo -e "${GREEN}✓ Demo service pod is Running${NC}"
fi

# Check if services exist
if kubectl get svc demo-service -n k8s-demo &> /dev/null; then
    echo -e "${GREEN}✓ Demo service ClusterIP service is available${NC}"
    kubectl get svc demo-service -n k8s-demo
fi

if kubectl get svc demo-service-external -n k8s-demo &> /dev/null; then
    echo -e "${GREEN}✓ Demo service LoadBalancer service is available${NC}"
    EXTERNAL_IP=$(kubectl get svc demo-service-external -n k8s-demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")
    if [ "$EXTERNAL_IP" != "pending" ] && [ -n "$EXTERNAL_IP" ]; then
        echo "  External URL: http://${EXTERNAL_IP}"
    else
        echo "  External IP: pending (may take a few minutes)"
    fi
fi

# Test application
echo ""
echo -e "${YELLOW}Step 6: Testing application...${NC}"
sleep 3
if kubectl exec -n k8s-demo deployment/demo-service -- wget -qO- http://localhost:8080/health 2>/dev/null | grep -q "ok"; then
    echo -e "${GREEN}✓ Application is responding${NC}"
else
    echo -e "${YELLOW}Warning: Could not verify application health endpoint${NC}"
fi

echo ""
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo ""
echo "Demo service (Project Dashboard) is deployed and ready!"
echo ""
echo "What it provides:"
echo "  - Project overview and documentation"
echo "  - Links to all services (Online Boutique, Monitoring, Testing, ArgoCD)"
echo "  - Service URLs and access information"
echo "  - Architecture and feature descriptions"
echo ""
echo "Access the dashboard:"
echo "  - Internal: http://demo-service.k8s-demo.svc.cluster.local:80"
echo "  - Port-forward: kubectl port-forward -n k8s-demo svc/demo-service 8080:80"
echo "  - Then open: http://localhost:8080"
if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "pending" ]; then
    echo "  - External: http://${EXTERNAL_IP}"
fi
echo ""
echo "Next steps:"
echo "  1. Port-forward: kubectl port-forward -n k8s-demo svc/demo-service 8080:80"
echo "  2. Open browser: http://localhost:8080"
echo "  3. Explore all services and their URLs from the dashboard"
echo ""

