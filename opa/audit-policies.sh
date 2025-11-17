#!/bin/bash

# Unified OPA Policy Audit Script
# Audits all OPA policies for compliance
# Usage: ./audit-policies.sh [policy] [namespace]
#   policy: resource-limits, latest-tags, readonly-fs, privileged, labels, all, all-namespace
#   namespace: target namespace (default: online-boutique)

set -e

POLICY="${1}"
NAMESPACE="${2:-online-boutique}"

# Define help function
show_help() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  OPA Policy Audit Script"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Usage: $0 [policy] [namespace]"
    echo ""
    echo "Available Policies:"
    echo "  resource-limits    - Check for CPU/memory limits"
    echo "  latest-tags        - Check for :latest image tags"
    echo "  readonly-fs        - Check for read-only root filesystem"
    echo "  privileged         - Check for privileged containers"
    echo "  labels             - Check for required labels (app, team, environment)"
    echo "  all                - Run all policies (single namespace)"
    echo "  all-namespace      - Run all policies (all namespaces)"
    echo ""
    echo "Options:"
    echo "  -h, --help         - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 resource-limits                    # Audit resource limits in online-boutique"
    echo "  $0 resource-limits monitoring         # Audit resource limits in monitoring namespace"
    echo "  $0 all                                # Audit all policies in online-boutique"
    echo "  $0 all monitoring                     # Audit all policies in monitoring namespace"
    echo "  $0 all-namespace                      # Audit all policies in all namespaces"
    echo ""
    echo "Default namespace: online-boutique"
    echo ""
}

# Check for help flag
if [ "$POLICY" = "-h" ] || [ "$POLICY" = "--help" ]; then
    show_help
    exit 0
fi

# Set default policy if not provided (defaults to "all")
POLICY="${POLICY:-all}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to audit a single policy
audit_policy() {
    local policy_name=$1
    local ns=$2
    
    case "$policy_name" in
        resource-limits)
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${YELLOW}  Policy: Require Resource Limits (CPU/Memory)${NC}"
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            audit_resource_limits "$ns"
            ;;
        latest-tags)
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${YELLOW}  Policy: Disallow Latest Tags${NC}"
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            audit_latest_tags "$ns"
            ;;
        readonly-fs)
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${YELLOW}  Policy: Require Read-Only Root Filesystem${NC}"
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            audit_readonly_fs "$ns"
            ;;
        privileged)
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${YELLOW}  Policy: Disallow Privileged Containers${NC}"
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            audit_privileged "$ns"
            ;;
        labels)
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${YELLOW}  Policy: Require Specific Labels${NC}"
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            audit_labels "$ns"
            ;;
        *)
            echo -e "${RED}Unknown policy: $policy_name${NC}"
            return 1
            ;;
    esac
}

# Audit Resource Limits
audit_resource_limits() {
    local ns=$1
    local pods_json=$(kubectl get pods -n "$ns" -o json 2>/dev/null || echo '{"items":[]}')
    local total=$(echo "$pods_json" | jq '.items | length')
    
    if [ "$total" -eq 0 ]; then
        echo "⚠️  No pods found in namespace '$ns'"
        return 0
    fi
    
    local compliant=0
    local non_compliant=0
    
    for i in $(seq 0 $((total - 1))); do
        local pod_json=$(echo "$pods_json" | jq -r ".items[$i]")
        local pod_name=$(echo "$pod_json" | jq -r '.metadata.name')
        local container_count=$(echo "$pod_json" | jq '.spec.containers | length')
        local is_compliant=true
        local violations=()
        
        for j in $(seq 0 $((container_count - 1))); do
            local container_json=$(echo "$pod_json" | jq -r ".spec.containers[$j]")
            local container_name=$(echo "$container_json" | jq -r '.name')
            local cpu_limit=$(echo "$container_json" | jq -r '.resources.limits.cpu // empty')
            local memory_limit=$(echo "$container_json" | jq -r '.resources.limits.memory // empty')
            
            if [ -z "$cpu_limit" ] || [ "$cpu_limit" = "null" ] || [ "$cpu_limit" = "empty" ]; then
                is_compliant=false
                violations+=("Container '$container_name' missing CPU limit")
            fi
            
            if [ -z "$memory_limit" ] || [ "$memory_limit" = "null" ] || [ "$memory_limit" = "empty" ]; then
                is_compliant=false
                violations+=("Container '$container_name' missing memory limit")
            fi
        done
        
        if [ "$is_compliant" = "true" ]; then
            echo -e "${GREEN}✅${NC} $pod_name"
            compliant=$((compliant + 1))
        else
            echo -e "${RED}❌${NC} $pod_name"
            for v in "${violations[@]}"; do
                echo "   • $v"
            done
            non_compliant=$((non_compliant + 1))
        fi
    done
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Total Pods: $total"
    echo -e "${GREEN}✅ Compliant: $compliant${NC}"
    echo -e "${RED}❌ Non-Compliant: $non_compliant${NC}"
    echo ""
}

# Audit Latest Tags
audit_latest_tags() {
    local ns=$1
    local pods_json=$(kubectl get pods -n "$ns" -o json 2>/dev/null || echo '{"items":[]}')
    local total=$(echo "$pods_json" | jq '.items | length')
    
    if [ "$total" -eq 0 ]; then
        echo "⚠️  No pods found in namespace '$ns'"
        return 0
    fi
    
    local compliant=0
    local non_compliant=0
    
    for i in $(seq 0 $((total - 1))); do
        local pod_json=$(echo "$pods_json" | jq -r ".items[$i]")
        local pod_name=$(echo "$pod_json" | jq -r '.metadata.name')
        local container_count=$(echo "$pod_json" | jq '.spec.containers | length')
        local is_compliant=true
        local violations=()
        
        for j in $(seq 0 $((container_count - 1))); do
            local container_json=$(echo "$pod_json" | jq -r ".spec.containers[$j]")
            local container_name=$(echo "$container_json" | jq -r '.name')
            local image=$(echo "$container_json" | jq -r '.image')
            
            if echo "$image" | grep -q ":latest" || ! echo "$image" | grep -q ":"; then
                is_compliant=false
                violations+=("Container '$container_name' uses image: $image")
            fi
        done
        
        if [ "$is_compliant" = "true" ]; then
            echo -e "${GREEN}✅${NC} $pod_name"
            compliant=$((compliant + 1))
        else
            echo -e "${RED}❌${NC} $pod_name"
            for v in "${violations[@]}"; do
                echo "   • $v"
            done
            non_compliant=$((non_compliant + 1))
        fi
    done
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Total Pods: $total"
    echo -e "${GREEN}✅ Compliant: $compliant${NC}"
    echo -e "${RED}❌ Non-Compliant: $non_compliant${NC}"
    echo ""
}

# Audit Read-Only Filesystem
audit_readonly_fs() {
    local ns=$1
    local pods_json=$(kubectl get pods -n "$ns" -o json 2>/dev/null || echo '{"items":[]}')
    local total=$(echo "$pods_json" | jq '.items | length')
    
    if [ "$total" -eq 0 ]; then
        echo "⚠️  No pods found in namespace '$ns'"
        return 0
    fi
    
    local compliant=0
    local non_compliant=0
    
    for i in $(seq 0 $((total - 1))); do
        local pod_json=$(echo "$pods_json" | jq -r ".items[$i]")
        local pod_name=$(echo "$pod_json" | jq -r '.metadata.name')
        local container_count=$(echo "$pod_json" | jq '.spec.containers | length')
        local pod_readonly_fs=$(echo "$pod_json" | jq -r '.spec.securityContext.readOnlyRootFilesystem // empty')
        local is_compliant=true
        local violations=()
        
        for j in $(seq 0 $((container_count - 1))); do
            local container_json=$(echo "$pod_json" | jq -r ".spec.containers[$j]")
            local container_name=$(echo "$container_json" | jq -r '.name')
            local readonly_fs=$(echo "$container_json" | jq -r '.securityContext.readOnlyRootFilesystem // empty')
            
            if [ "$readonly_fs" != "true" ] && [ "$pod_readonly_fs" != "true" ]; then
                is_compliant=false
                violations+=("Container '$container_name' does not have readOnlyRootFilesystem: true")
            fi
        done
        
        if [ "$is_compliant" = "true" ]; then
            echo -e "${GREEN}✅${NC} $pod_name"
            compliant=$((compliant + 1))
        else
            echo -e "${RED}❌${NC} $pod_name"
            for v in "${violations[@]}"; do
                echo "   • $v"
            done
            non_compliant=$((non_compliant + 1))
        fi
    done
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Total Pods: $total"
    echo -e "${GREEN}✅ Compliant: $compliant${NC}"
    echo -e "${RED}❌ Non-Compliant: $non_compliant${NC}"
    echo ""
}

# Audit Privileged Containers
audit_privileged() {
    local ns=$1
    local pods_json=$(kubectl get pods -n "$ns" -o json 2>/dev/null || echo '{"items":[]}')
    local total=$(echo "$pods_json" | jq '.items | length')
    
    if [ "$total" -eq 0 ]; then
        echo "⚠️  No pods found in namespace '$ns'"
        return 0
    fi
    
    local compliant=0
    local non_compliant=0
    
    for i in $(seq 0 $((total - 1))); do
        local pod_json=$(echo "$pods_json" | jq -r ".items[$i]")
        local pod_name=$(echo "$pod_json" | jq -r '.metadata.name')
        local container_count=$(echo "$pod_json" | jq '.spec.containers | length')
        local is_compliant=true
        local violations=()
        
        for j in $(seq 0 $((container_count - 1))); do
            local container_json=$(echo "$pod_json" | jq -r ".spec.containers[$j]")
            local container_name=$(echo "$container_json" | jq -r '.name')
            local privileged=$(echo "$container_json" | jq -r '.securityContext.privileged // empty')
            
            if [ "$privileged" = "true" ]; then
                is_compliant=false
                violations+=("Container '$container_name' is running in privileged mode")
            fi
        done
        
        if [ "$is_compliant" = "true" ]; then
            echo -e "${GREEN}✅${NC} $pod_name"
            compliant=$((compliant + 1))
        else
            echo -e "${RED}❌${NC} $pod_name"
            for v in "${violations[@]}"; do
                echo "   • $v"
            done
            non_compliant=$((non_compliant + 1))
        fi
    done
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Total Pods: $total"
    echo -e "${GREEN}✅ Compliant: $compliant${NC}"
    echo -e "${RED}❌ Non-Compliant: $non_compliant${NC}"
    echo ""
}

# Audit Required Labels
audit_labels() {
    local ns=$1
    local pods_json=$(kubectl get pods -n "$ns" -o json 2>/dev/null || echo '{"items":[]}')
    local total=$(echo "$pods_json" | jq '.items | length')
    
    if [ "$total" -eq 0 ]; then
        echo "⚠️  No pods found in namespace '$ns'"
        return 0
    fi
    
    local required_labels=("app" "team" "environment")
    local compliant=0
    local non_compliant=0
    
    echo "Required Labels: ${required_labels[*]}"
    echo ""
    
    for i in $(seq 0 $((total - 1))); do
        local pod_json=$(echo "$pods_json" | jq -r ".items[$i]")
        local pod_name=$(echo "$pod_json" | jq -r '.metadata.name')
        local is_compliant=true
        local missing_labels=()
        
        for label in "${required_labels[@]}"; do
            local label_value=$(echo "$pod_json" | jq -r ".metadata.labels.\"$label\" // empty")
            if [ -z "$label_value" ] || [ "$label_value" = "null" ] || [ "$label_value" = "empty" ]; then
                is_compliant=false
                missing_labels+=("$label")
            fi
        done
        
        if [ "$is_compliant" = "true" ]; then
            echo -e "${GREEN}✅${NC} $pod_name"
            compliant=$((compliant + 1))
        else
            echo -e "${RED}❌${NC} $pod_name"
            echo "   • Missing labels: ${missing_labels[*]}"
            non_compliant=$((non_compliant + 1))
        fi
    done
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Total Pods: $total"
    echo -e "${GREEN}✅ Compliant: $compliant${NC}"
    echo -e "${RED}❌ Non-Compliant: $non_compliant${NC}"
    echo ""
}

# Main execution
if [ "$POLICY" = "all" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Comprehensive OPA Policy Audit - All Policies"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Namespace: $NAMESPACE"
    echo ""
    
    policies=("resource-limits" "latest-tags" "readonly-fs" "privileged" "labels")
    for policy in "${policies[@]}"; do
        audit_policy "$policy" "$NAMESPACE"
        echo ""
    done
    
elif [ "$POLICY" = "all-namespace" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Comprehensive OPA Policy Audit - All Namespaces"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Get all namespaces (excluding system namespaces)
    namespaces=$(kubectl get namespaces -o json | jq -r '.items[] | select(.metadata.name | test("^(kube-|gatekeeper-|argocd$)") | not) | .metadata.name')
    
    policies=("resource-limits" "latest-tags" "readonly-fs" "privileged" "labels")
    
    for ns in $namespaces; do
        pod_count=$(kubectl get pods -n "$ns" -o json 2>/dev/null | jq '.items | length' || echo "0")
        
        if [ "$pod_count" -eq 0 ]; then
            continue
        fi
        
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  Namespace: $ns"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        for policy in "${policies[@]}"; do
            audit_policy "$policy" "$ns"
        done
        echo ""
    done
    
elif [ -n "$POLICY" ]; then
    # Validate policy name
    valid_policies=("resource-limits" "latest-tags" "readonly-fs" "privileged" "labels")
    is_valid=false
    for valid_policy in "${valid_policies[@]}"; do
        if [ "$POLICY" = "$valid_policy" ]; then
            is_valid=true
            break
        fi
    done
    
    if [ "$is_valid" = "false" ]; then
        echo -e "${RED}❌ Unknown policy: $POLICY${NC}"
        echo ""
        show_help
        exit 1
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  OPA Policy Audit"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Namespace: $NAMESPACE"
    echo ""
    audit_policy "$POLICY" "$NAMESPACE"
fi

