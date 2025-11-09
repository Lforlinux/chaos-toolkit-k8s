#!/bin/bash

# Enhanced Monitoring Cleanup Script
# This script deletes all monitoring resources (Prometheus, Grafana, kube-state-metrics, node-exporter)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}=== Enhanced Monitoring Cleanup Script ===${NC}"
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
if ! kubectl get namespace monitoring &> /dev/null; then
    echo -e "${YELLOW}Namespace 'monitoring' does not exist. Nothing to delete.${NC}"
    exit 0
fi

# Show what will be deleted
echo -e "${YELLOW}This will delete all resources in the 'monitoring' namespace:${NC}"
echo "  - Prometheus deployment and services"
echo "  - Grafana deployment and services"
echo "  - kube-state-metrics deployment"
echo "  - node-exporter DaemonSet"
echo "  - All ConfigMaps and Secrets"
echo "  - All RBAC resources (ServiceAccounts, Roles, RoleBindings)"
echo "  - The namespace itself"
echo ""

# Optional: Add confirmation prompt (uncomment to enable)
# read -p "Are you sure you want to continue? (yes/no): " confirm
# if [ "$confirm" != "yes" ]; then
#     echo "Deletion cancelled."
#     exit 0
# fi

# Define manifest files
PROMETHEUS_FILE="${SCRIPT_DIR}/prometheus/prometheus-enhanced.yaml"
KUBE_STATE_METRICS_FILE="${SCRIPT_DIR}/prometheus/kube-state-metrics.yaml"
NODE_EXPORTER_FILE="${SCRIPT_DIR}/prometheus/node-exporter.yaml"
GRAFANA_FILE="${SCRIPT_DIR}/grafana/grafana-enhanced.yaml"

echo -e "${YELLOW}Step 1: Listing resources to be deleted...${NC}"
kubectl get all -n monitoring 2>/dev/null || echo "No resources found or namespace is empty"
echo ""

echo -e "${YELLOW}Step 2: Deleting Grafana...${NC}"
if [ -f "${GRAFANA_FILE}" ]; then
    kubectl delete -f "${GRAFANA_FILE}" --ignore-not-found=true
    echo -e "${GREEN}✓ Grafana resources deleted${NC}"
else
    # Try to delete by name if file doesn't exist
    kubectl delete deployment grafana -n monitoring --ignore-not-found=true
    kubectl delete service grafana grafana-external -n monitoring --ignore-not-found=true
    kubectl delete configmap grafana-config grafana-dashboards -n monitoring --ignore-not-found=true
fi
echo ""

echo -e "${YELLOW}Step 3: Deleting Prometheus...${NC}"
if [ -f "${PROMETHEUS_FILE}" ]; then
    kubectl delete -f "${PROMETHEUS_FILE}" --ignore-not-found=true
    echo -e "${GREEN}✓ Prometheus resources deleted${NC}"
else
    # Try to delete by name if file doesn't exist
    kubectl delete deployment prometheus -n monitoring --ignore-not-found=true
    kubectl delete service prometheus prometheus-external -n monitoring --ignore-not-found=true
    kubectl delete configmap prometheus-config -n monitoring --ignore-not-found=true
    kubectl delete serviceaccount prometheus -n monitoring --ignore-not-found=true
    kubectl delete clusterrole prometheus --ignore-not-found=true
    kubectl delete clusterrolebinding prometheus --ignore-not-found=true
fi
echo ""

echo -e "${YELLOW}Step 4: Deleting kube-state-metrics...${NC}"
if [ -f "${KUBE_STATE_METRICS_FILE}" ]; then
    kubectl delete -f "${KUBE_STATE_METRICS_FILE}" --ignore-not-found=true
    echo -e "${GREEN}✓ kube-state-metrics resources deleted${NC}"
else
    # Try to delete by name if file doesn't exist
    kubectl delete deployment kube-state-metrics -n monitoring --ignore-not-found=true
    kubectl delete service kube-state-metrics -n monitoring --ignore-not-found=true
    kubectl delete serviceaccount kube-state-metrics -n monitoring --ignore-not-found=true
    kubectl delete clusterrole kube-state-metrics --ignore-not-found=true
    kubectl delete clusterrolebinding kube-state-metrics --ignore-not-found=true
fi
echo ""

echo -e "${YELLOW}Step 5: Deleting node-exporter...${NC}"
if [ -f "${NODE_EXPORTER_FILE}" ]; then
    kubectl delete -f "${NODE_EXPORTER_FILE}" --ignore-not-found=true
    echo -e "${GREEN}✓ node-exporter resources deleted${NC}"
else
    # Try to delete by name if file doesn't exist
    kubectl delete daemonset node-exporter -n monitoring --ignore-not-found=true
    kubectl delete service node-exporter -n monitoring --ignore-not-found=true
    kubectl delete serviceaccount node-exporter -n monitoring --ignore-not-found=true
    kubectl delete clusterrole node-exporter --ignore-not-found=true
    kubectl delete clusterrolebinding node-exporter --ignore-not-found=true
fi
echo ""

echo -e "${YELLOW}Step 6: Cleaning up any remaining resources...${NC}"
# Delete any remaining ConfigMaps, Secrets, etc.
kubectl delete configmap --all -n monitoring --ignore-not-found=true 2>/dev/null || true
kubectl delete secret --all -n monitoring --ignore-not-found=true 2>/dev/null || true
kubectl delete ingress --all -n monitoring --ignore-not-found=true 2>/dev/null || true
echo -e "${GREEN}✓ Remaining resources cleaned up${NC}"
echo ""

echo -e "${YELLOW}Step 7: Waiting for resources to terminate...${NC}"
# Wait for pods to terminate
TIMEOUT=60
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    POD_COUNT=$(kubectl get pods -n monitoring --no-headers 2>/dev/null | wc -l | tr -d ' ')
    if [ "$POD_COUNT" -eq 0 ]; then
        break
    fi
    echo -e "${BLUE}  Waiting for pods to terminate... (${ELAPSED}s/${TIMEOUT}s)${NC}"
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo -e "${YELLOW}Warning: Some pods may still be terminating after ${TIMEOUT}s${NC}"
    kubectl get pods -n monitoring 2>/dev/null || true
else
    echo -e "${GREEN}✓ All pods terminated${NC}"
fi
echo ""

echo -e "${YELLOW}Step 8: Deleting namespace...${NC}"
kubectl delete namespace monitoring --ignore-not-found=true

# Wait for namespace to be deleted
echo -e "${BLUE}  Waiting for namespace to be fully deleted...${NC}"
TIMEOUT=30
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    if ! kubectl get namespace monitoring &> /dev/null; then
        break
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

if kubectl get namespace monitoring &> /dev/null; then
    echo -e "${YELLOW}Warning: Namespace deletion is taking longer than expected${NC}"
    echo "You can check status with: kubectl get namespace monitoring"
else
    echo -e "${GREEN}✓ Namespace deleted${NC}"
fi
echo ""

echo -e "${YELLOW}Step 9: Cleaning up ClusterRole and ClusterRoleBinding resources...${NC}"
# Clean up any remaining cluster-level resources
kubectl delete clusterrole prometheus kube-state-metrics node-exporter --ignore-not-found=true 2>/dev/null || true
kubectl delete clusterrolebinding prometheus kube-state-metrics node-exporter --ignore-not-found=true 2>/dev/null || true
echo -e "${GREEN}✓ Cluster-level resources cleaned up${NC}"
echo ""

echo -e "${YELLOW}Step 10: Verifying cleanup...${NC}"
if kubectl get namespace monitoring &> /dev/null; then
    echo -e "${RED}Warning: Namespace still exists${NC}"
    echo "Remaining resources:"
    kubectl get all -n monitoring 2>/dev/null || true
else
    echo -e "${GREEN}✓ Namespace 'monitoring' has been completely removed${NC}"
fi

# Check for remaining cluster-level resources
REMAINING_ROLES=$(kubectl get clusterrole | grep -E "prometheus|kube-state-metrics|node-exporter" | wc -l | tr -d ' ')
REMAINING_BINDINGS=$(kubectl get clusterrolebinding | grep -E "prometheus|kube-state-metrics|node-exporter" | wc -l | tr -d ' ')

if [ "$REMAINING_ROLES" -gt 0 ] || [ "$REMAINING_BINDINGS" -gt 0 ]; then
    echo -e "${YELLOW}Warning: Some cluster-level resources may still exist${NC}"
    echo "Check with: kubectl get clusterrole,clusterrolebinding | grep -E 'prometheus|kube-state-metrics|node-exporter'"
else
    echo -e "${GREEN}✓ All cluster-level resources cleaned up${NC}"
fi

echo ""
echo -e "${GREEN}=== Cleanup Complete ===${NC}"
echo ""
echo "All monitoring resources have been deleted."
echo ""
echo "Note: If you had LoadBalancer services, it may take a few minutes"
echo "      for the cloud provider to release the external IPs."
echo ""
echo "Deleted components:"
echo "  ✓ Prometheus"
echo "  ✓ Grafana"
echo "  ✓ kube-state-metrics"
echo "  ✓ node-exporter"
echo "  ✓ All associated RBAC resources"
echo "  ✓ monitoring namespace"
echo ""

