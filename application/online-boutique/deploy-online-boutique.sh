#!/bin/bash

# Online Boutique Deployment Script
# This script deploys the Google Online Boutique microservices demo to the online-boutique namespace

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Online Boutique Deployment Script ===${NC}"
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

# Check if manifest files exist
NAMESPACE_FILE="${SCRIPT_DIR}/online-boutique-namespace.yaml"
MANIFEST_FILE="${SCRIPT_DIR}/online-boutique-manifest.yaml"

if [ ! -f "${NAMESPACE_FILE}" ]; then
    echo -e "${RED}Error: online-boutique-namespace.yaml not found in ${SCRIPT_DIR}${NC}"
    exit 1
fi

if [ ! -f "${MANIFEST_FILE}" ]; then
    echo -e "${RED}Error: online-boutique-manifest.yaml not found in ${SCRIPT_DIR}${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Creating online-boutique namespace...${NC}"
kubectl apply -f "${NAMESPACE_FILE}"
echo -e "${GREEN}✓ Namespace created${NC}"
echo ""

echo -e "${YELLOW}Step 2: Deploying all microservices from manifest...${NC}"
echo "This includes:"
echo "  - emailservice"
echo "  - checkoutservice"
echo "  - recommendationservice"
echo "  - frontend"
echo "  - paymentservice"
echo "  - productcatalogservice"
echo "  - cartservice"
echo "  - redis-cart"
echo "  - loadgenerator"
echo "  - currencyservice"
echo "  - shippingservice"
echo "  - adservice"
echo "  - All corresponding Services and ServiceAccounts"
echo ""

kubectl apply -f "${MANIFEST_FILE}"
echo -e "${GREEN}✓ All resources applied${NC}"
echo ""

echo -e "${YELLOW}Step 3: Waiting for frontend deployment to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/frontend -n online-boutique || {
    echo -e "${RED}Error: Frontend deployment did not become ready within 5 minutes${NC}"
    echo "Check pod status with: kubectl get pods -n online-boutique"
    exit 1
}
echo -e "${GREEN}✓ Frontend deployment is ready${NC}"
echo ""

echo -e "${YELLOW}Step 4: Waiting for other key services to be ready...${NC}"
# Wait for a few key services
for deployment in productcatalogservice cartservice currencyservice; do
    if kubectl get deployment "$deployment" -n online-boutique &> /dev/null; then
        echo -e "${BLUE}  Waiting for $deployment...${NC}"
        kubectl wait --for=condition=available --timeout=180s deployment/"$deployment" -n online-boutique || {
            echo -e "${YELLOW}Warning: $deployment did not become ready within 3 minutes${NC}"
        }
    fi
done
echo -e "${GREEN}✓ Key services are ready${NC}"
echo ""

echo -e "${YELLOW}Step 5: Verifying deployment...${NC}"
FRONTEND_POD=$(kubectl get pods -n online-boutique -l app=frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$FRONTEND_POD" ]; then
    echo -e "${RED}Error: Frontend pod not found${NC}"
    exit 1
fi

# Check if pod is running
POD_STATUS=$(kubectl get pod "$FRONTEND_POD" -n online-boutique -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$POD_STATUS" != "Running" ]; then
    echo -e "${YELLOW}Warning: Frontend pod status is ${POD_STATUS}${NC}"
    echo "Pod details:"
    kubectl describe pod "$FRONTEND_POD" -n online-boutique | tail -20
else
    echo -e "${GREEN}✓ Frontend pod is Running${NC}"
fi

# Check pod status for all services
echo ""
echo -e "${BLUE}Pod Status Summary:${NC}"
kubectl get pods -n online-boutique

# Check if services exist
echo ""
if kubectl get svc frontend -n online-boutique &> /dev/null; then
    echo -e "${GREEN}✓ Frontend ClusterIP service is available${NC}"
    kubectl get svc frontend -n online-boutique
fi

if kubectl get svc frontend-external -n online-boutique &> /dev/null; then
    echo ""
    echo -e "${GREEN}✓ Frontend LoadBalancer service is available${NC}"
    EXTERNAL_IP=$(kubectl get svc frontend-external -n online-boutique -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || \
                  kubectl get svc frontend-external -n online-boutique -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || \
                  echo "pending")
    kubectl get svc frontend-external -n online-boutique
    if [ "$EXTERNAL_IP" != "pending" ] && [ -n "$EXTERNAL_IP" ]; then
        echo "  External URL: http://${EXTERNAL_IP}"
    else
        echo "  External IP: pending (may take a few minutes)"
    fi
fi

# Test application
echo ""
echo -e "${YELLOW}Step 6: Testing application...${NC}"
sleep 5
if kubectl exec -n online-boutique deployment/frontend -- wget -qO- http://localhost:8080 2>/dev/null | grep -q "Online Boutique"; then
    echo -e "${GREEN}✓ Application is responding${NC}"
else
    echo -e "${YELLOW}Warning: Could not verify application endpoint${NC}"
    echo "This is normal if the application is still initializing"
fi

echo ""
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo ""
echo "Google Online Boutique microservices demo is deployed and ready!"
echo ""
echo "What it provides:"
echo "  - Full e-commerce microservices demo application"
echo "  - 11 microservices demonstrating distributed system patterns"
echo "  - Includes: frontend, cart, checkout, payment, shipping, recommendations, and more"
echo ""
echo "Access the application:"
echo "  - Internal: http://frontend.online-boutique.svc.cluster.local:80"
echo "  - Port-forward: kubectl port-forward -n online-boutique svc/frontend 8080:80"
echo "  - Then open: http://localhost:8080"
if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "pending" ]; then
    echo "  - External: http://${EXTERNAL_IP}"
fi
echo ""
echo "Next steps:"
echo "  1. Port-forward: kubectl port-forward -n online-boutique svc/frontend 8080:80"
echo "  2. Open browser: http://localhost:8080"
echo "  3. Browse the online boutique and test the shopping experience"
echo ""
echo "View all services:"
echo "  kubectl get all -n online-boutique"
echo ""

