#!/bin/bash

# ArgoCD Deployment Script
# This script deploys ArgoCD GitOps platform to the argocd namespace

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARGOCD_INSTALL_URL="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
LOADBALANCER_FILE="${SCRIPT_DIR}/argocd-loadbalancer.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== ArgoCD Deployment Script ===${NC}"
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

echo -e "${YELLOW}Step 1: Creating argocd namespace...${NC}"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Namespace ready${NC}"
echo ""

echo -e "${YELLOW}Step 2: Installing ArgoCD from official manifests...${NC}"
echo "Downloading and applying ArgoCD installation manifests..."
if ! kubectl apply -n argocd -f "${ARGOCD_INSTALL_URL}"; then
    echo -e "${RED}Error: Failed to install ArgoCD${NC}"
    echo "Please check your internet connection and try again"
    exit 1
fi
echo -e "${GREEN}✓ ArgoCD manifests applied${NC}"
echo ""

echo -e "${YELLOW}Step 3: Waiting for ArgoCD components to be ready...${NC}"
echo "This may take 2-5 minutes..."
echo ""

# Wait for key components
COMPONENTS=("argocd-server" "argocd-repo-server" "argocd-application-controller" "argocd-redis")
for component in "${COMPONENTS[@]}"; do
    if kubectl wait --for=condition=available --timeout=300s deployment/"${component}" -n argocd 2>/dev/null; then
        echo -e "${GREEN}✓ ${component} is ready${NC}"
    else
        echo -e "${YELLOW}⚠ ${component} not ready yet (may still be starting)${NC}"
    fi
done

# Wait specifically for argocd-server as it's the main component
echo ""
echo -e "${YELLOW}Waiting for ArgoCD server to be fully ready...${NC}"
if kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd; then
    echo -e "${GREEN}✓ ArgoCD server is ready${NC}"
else
    echo -e "${RED}Error: ArgoCD server did not become ready within 5 minutes${NC}"
    echo "Check pod status with: kubectl get pods -n argocd"
    exit 1
fi
echo ""

echo -e "${YELLOW}Step 4: Verifying deployment...${NC}"
ARGOCD_POD=$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$ARGOCD_POD" ]; then
    echo -e "${RED}Error: ArgoCD server pod not found${NC}"
    exit 1
fi

# Check if pod is running
POD_STATUS=$(kubectl get pod "$ARGOCD_POD" -n argocd -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$POD_STATUS" != "Running" ]; then
    echo -e "${YELLOW}Warning: ArgoCD server pod status is ${POD_STATUS}${NC}"
    echo "Pod details:"
    kubectl describe pod "$ARGOCD_POD" -n argocd | tail -20
else
    echo -e "${GREEN}✓ ArgoCD server pod is Running${NC}"
fi

# Check if service exists
if kubectl get svc argocd-server -n argocd &> /dev/null; then
    echo -e "${GREEN}✓ ArgoCD server service is available${NC}"
    kubectl get svc argocd-server -n argocd
else
    echo -e "${RED}Error: ArgoCD server service not found${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}Step 5: Deploying LoadBalancer service (optional)...${NC}"
if [ -f "${LOADBALANCER_FILE}" ]; then
    kubectl apply -f "${LOADBALANCER_FILE}"
    echo -e "${GREEN}✓ LoadBalancer service applied${NC}"
    
    # Wait a moment for LoadBalancer to get an IP
    sleep 5
    EXTERNAL_IP=$(kubectl get svc argocd-server-loadbalancer -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")
    if [ "$EXTERNAL_IP" != "pending" ] && [ -n "$EXTERNAL_IP" ]; then
        echo "  External URL: https://${EXTERNAL_IP}"
    else
        echo "  External IP: pending (may take a few minutes)"
    fi
else
    echo -e "${YELLOW}⚠ LoadBalancer file not found, skipping${NC}"
fi
echo ""

echo -e "${YELLOW}Step 6: Retrieving admin credentials...${NC}"
# Wait a bit for secret to be created
sleep 5
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "")
if [ -z "$ARGOCD_PASSWORD" ]; then
    # Try alternative method
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "")
fi

if [ -n "$ARGOCD_PASSWORD" ]; then
    echo -e "${GREEN}✓ Admin credentials retrieved${NC}"
else
    echo -e "${YELLOW}⚠ Could not retrieve admin password${NC}"
    echo "  You may need to wait a few more seconds for the secret to be created"
    echo "  Try: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
fi

echo ""
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo ""
echo "ArgoCD is deployed and ready!"
echo ""
echo "Access ArgoCD:"
echo "  - Port-forward: kubectl port-forward -n argocd svc/argocd-server 8080:443"
echo "  - Then open: https://localhost:8080"
if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "pending" ]; then
    echo "  - External: https://${EXTERNAL_IP}"
fi
echo ""
echo "Login credentials:"
echo "  Username: ${BLUE}admin${NC}"
if [ -n "$ARGOCD_PASSWORD" ]; then
    echo "  Password: ${BLUE}${ARGOCD_PASSWORD}${NC}"
else
    echo "  Password: ${YELLOW}(run: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)${NC}"
fi
echo ""
echo "ArgoCD CLI Installation (optional):"
echo "  Linux:"
echo "    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
echo "    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd"
echo "    rm argocd-linux-amd64"
echo ""
echo "  macOS:"
echo "    brew install argocd"
echo ""
echo "Next steps:"
echo "  1. Port-forward: kubectl port-forward -n argocd svc/argocd-server 8080:443"
echo "  2. Access UI: https://localhost:8080"
echo "  3. Login with admin credentials above"
echo "  4. Create applications to manage your microservices and monitoring stack"
echo "  5. Example apps: kubectl apply -f argocd/microservices-app-local.yaml"
echo ""

