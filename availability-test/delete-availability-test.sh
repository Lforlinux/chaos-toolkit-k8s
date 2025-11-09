#!/bin/bash

# Availability Test Cleanup Script
# This script deletes all resources for the Availability Test application

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}=== Availability Test Cleanup Script ===${NC}"
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
if ! kubectl get namespace availability-test &> /dev/null; then
    echo -e "${YELLOW}Namespace 'availability-test' does not exist. Nothing to delete.${NC}"
    exit 0
fi

# Show what will be deleted
echo -e "${YELLOW}This will delete all resources in the 'availability-test' namespace:${NC}"
echo "  - Availability test application deployment"
echo "  - LoadBalancer service"
echo "  - ConfigMap (application code)"
echo "  - Ingress (if exists)"
echo "  - The namespace itself"
echo ""

# Optional: Add confirmation prompt (uncomment to enable)
# read -p "Are you sure you want to continue? (yes/no): " confirm
# if [ "$confirm" != "yes" ]; then
#     echo "Deletion cancelled."
#     exit 0
# fi

# Check if manifest files exist (optional, for graceful deletion)
DEPLOYMENT_FILE="${SCRIPT_DIR}/deployment.yaml"
LOADBALANCER_FILE="${SCRIPT_DIR}/loadbalancer.yaml"
CONFIGMAP_FILE="${SCRIPT_DIR}/configmap.yaml"
NAMESPACE_FILE="${SCRIPT_DIR}/namespace.yaml"

echo -e "${YELLOW}Step 1: Listing resources to be deleted...${NC}"
kubectl get all -n availability-test 2>/dev/null || echo "No resources found or namespace is empty"
echo ""

echo -e "${YELLOW}Step 2: Deleting Ingress (if exists)...${NC}"
# Try to delete ingress by name if it exists
kubectl delete ingress availability-test-alb-ingress -n availability-test --ignore-not-found=true 2>/dev/null || true
kubectl delete ingress -n availability-test --all --ignore-not-found=true 2>/dev/null || true
echo -e "${GREEN}✓ Ingress checked/deleted${NC}"
echo ""

echo -e "${YELLOW}Step 3: Deleting all resources from manifest files...${NC}"
if [ -f "${LOADBALANCER_FILE}" ]; then
    kubectl delete -f "${LOADBALANCER_FILE}" --ignore-not-found=true
    echo -e "${GREEN}✓ LoadBalancer service deleted${NC}"
fi

if [ -f "${DEPLOYMENT_FILE}" ]; then
    kubectl delete -f "${DEPLOYMENT_FILE}" --ignore-not-found=true
    echo -e "${GREEN}✓ Deployment deleted${NC}"
fi

if [ -f "${CONFIGMAP_FILE}" ]; then
    kubectl delete -f "${CONFIGMAP_FILE}" --ignore-not-found=true
    echo -e "${GREEN}✓ ConfigMap deleted${NC}"
fi
echo ""

echo -e "${YELLOW}Step 4: Waiting for resources to terminate...${NC}"
# Wait for pods to terminate
TIMEOUT=60
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    POD_COUNT=$(kubectl get pods -n availability-test --no-headers 2>/dev/null | wc -l | tr -d ' ')
    if [ "$POD_COUNT" -eq 0 ]; then
        break
    fi
    echo -e "${BLUE}  Waiting for pods to terminate... (${ELAPSED}s/${TIMEOUT}s)${NC}"
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo -e "${YELLOW}Warning: Some pods may still be terminating after ${TIMEOUT}s${NC}"
    kubectl get pods -n availability-test 2>/dev/null || true
else
    echo -e "${GREEN}✓ All pods terminated${NC}"
fi
echo ""

echo -e "${YELLOW}Step 5: Deleting namespace...${NC}"
if [ -f "${NAMESPACE_FILE}" ]; then
    kubectl delete -f "${NAMESPACE_FILE}" --ignore-not-found=true
else
    kubectl delete namespace availability-test --ignore-not-found=true
fi

# Wait for namespace to be deleted
echo -e "${BLUE}  Waiting for namespace to be fully deleted...${NC}"
TIMEOUT=30
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    if ! kubectl get namespace availability-test &> /dev/null; then
        break
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

if kubectl get namespace availability-test &> /dev/null; then
    echo -e "${YELLOW}Warning: Namespace deletion is taking longer than expected${NC}"
    echo "You can check status with: kubectl get namespace availability-test"
else
    echo -e "${GREEN}✓ Namespace deleted${NC}"
fi
echo ""

echo -e "${YELLOW}Step 6: Verifying cleanup...${NC}"
if kubectl get namespace availability-test &> /dev/null; then
    echo -e "${RED}Warning: Namespace still exists${NC}"
    echo "Remaining resources:"
    kubectl get all -n availability-test 2>/dev/null || true
else
    echo -e "${GREEN}✓ Namespace 'availability-test' has been completely removed${NC}"
fi

echo ""
echo -e "${GREEN}=== Cleanup Complete ===${NC}"
echo ""
echo "All Availability Test resources have been deleted."
echo ""
echo "Note: If you had a LoadBalancer service, it may take a few minutes"
echo "      for the cloud provider to release the external IP."
echo "      If you used an ALB Ingress, the ALB may take a few minutes"
echo "      to be fully deleted from AWS."
echo ""

