#!/bin/bash

# Online Boutique Cleanup Script
# This script deletes all resources for the Google Online Boutique microservices demo

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}=== Online Boutique Cleanup Script ===${NC}"
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

# Check if namespace exists
if ! kubectl get namespace online-boutique &> /dev/null; then
    echo -e "${YELLOW}Namespace 'online-boutique' does not exist. Nothing to delete.${NC}"
    exit 0
fi

# Show what will be deleted
echo -e "${YELLOW}This will delete all resources in the 'online-boutique' namespace:${NC}"
echo "  - All microservices (11 services)"
echo "  - All deployments"
echo "  - All services (ClusterIP and LoadBalancer)"
echo "  - All service accounts"
echo "  - The namespace itself"
echo ""

# Optional: Add confirmation prompt (uncomment to enable)
# read -p "Are you sure you want to continue? (yes/no): " confirm
# if [ "$confirm" != "yes" ]; then
#     echo "Deletion cancelled."
#     exit 0
# fi

# Check if manifest files exist (optional, for graceful deletion)
MANIFEST_FILE="${SCRIPT_DIR}/online-boutique-manifest.yaml"
NAMESPACE_FILE="${SCRIPT_DIR}/online-boutique-namespace.yaml"

echo -e "${YELLOW}Step 1: Listing resources to be deleted...${NC}"
kubectl get all -n online-boutique 2>/dev/null || echo "No resources found or namespace is empty"
echo ""

echo -e "${YELLOW}Step 2: Deleting all resources from manifest...${NC}"
if [ -f "${MANIFEST_FILE}" ]; then
    kubectl delete -f "${MANIFEST_FILE}" --ignore-not-found=true
    echo -e "${GREEN}✓ Resources from manifest deleted${NC}"
else
    echo -e "${YELLOW}Warning: Manifest file not found, deleting namespace directly${NC}"
fi
echo ""

echo -e "${YELLOW}Step 3: Waiting for resources to terminate...${NC}"
# Wait for pods to terminate
TIMEOUT=60
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    POD_COUNT=$(kubectl get pods -n online-boutique --no-headers 2>/dev/null | wc -l | tr -d ' ')
    if [ "$POD_COUNT" -eq 0 ]; then
        break
    fi
    echo -e "${BLUE}  Waiting for pods to terminate... (${ELAPSED}s/${TIMEOUT}s)${NC}"
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo -e "${YELLOW}Warning: Some pods may still be terminating after ${TIMEOUT}s${NC}"
    kubectl get pods -n online-boutique 2>/dev/null || true
else
    echo -e "${GREEN}✓ All pods terminated${NC}"
fi
echo ""

echo -e "${YELLOW}Step 4: Deleting namespace...${NC}"
if [ -f "${NAMESPACE_FILE}" ]; then
    kubectl delete -f "${NAMESPACE_FILE}" --ignore-not-found=true
else
    kubectl delete namespace online-boutique --ignore-not-found=true
fi

# Wait for namespace to be deleted
echo -e "${BLUE}  Waiting for namespace to be fully deleted...${NC}"
TIMEOUT=30
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    if ! kubectl get namespace online-boutique &> /dev/null; then
        break
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

if kubectl get namespace online-boutique &> /dev/null; then
    echo -e "${YELLOW}Warning: Namespace deletion is taking longer than expected${NC}"
    echo "You can check status with: kubectl get namespace online-boutique"
else
    echo -e "${GREEN}✓ Namespace deleted${NC}"
fi
echo ""

echo -e "${YELLOW}Step 5: Verifying cleanup...${NC}"
if kubectl get namespace online-boutique &> /dev/null; then
    echo -e "${RED}Warning: Namespace still exists${NC}"
    echo "Remaining resources:"
    kubectl get all -n online-boutique 2>/dev/null || true
else
    echo -e "${GREEN}✓ Namespace 'online-boutique' has been completely removed${NC}"
fi

echo ""
echo -e "${GREEN}=== Cleanup Complete ===${NC}"
echo ""
echo "All Online Boutique resources have been deleted."
echo ""
echo "Note: If you had a LoadBalancer service, it may take a few minutes"
echo "      for the cloud provider to release the external IP."
echo ""

