#!/bin/bash

# Switch OPA Policy Enforcement Mode
# Usage: ./switch-enforcement-mode.sh <mode> [constraint-name]
# Modes: enforce, dryrun, warn

set -e

MODE="${1}"
CONSTRAINT_NAME="${2:-online-boutique-must-run-nonroot}"
CONSTRAINT_KIND="K8sRequiredNonRoot"

# Show help if requested or no mode provided
if [ -z "$MODE" ] || [ "$MODE" = "-h" ] || [ "$MODE" = "--help" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  OPA Policy Enforcement Mode Switcher"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Usage: $0 <mode> [constraint-name]"
    echo ""
    echo "Modes:"
    echo "  enforce  - BLOCK violations (production mode)"
    echo "  dryrun   - REPORT violations but allow (demo/audit mode) ⭐ Default"
    echo "  warn     - WARN about violations but allow (soft enforcement)"
    echo ""
    echo "Available Constraints:"
    echo "  1. online-boutique-must-run-nonroot          (Non-Root Users)"
    echo "  2. online-boutique-require-resource-limits   (Resource Limits)"
    echo "  3. online-boutique-disallow-latest-tag      (Disallow Latest Tags)"
    echo "  4. online-boutique-require-readonly-fs      (Read-Only Filesystem)"
    echo "  5. online-boutique-disallow-privileged      (Disallow Privileged)"
    echo "  6. online-boutique-require-labels           (Required Labels)"
    echo ""
    echo "Examples:"
    echo "  $0 dryrun                                    # Switch default constraint to dryrun"
    echo "  $0 enforce online-boutique-must-run-nonroot  # Switch non-root policy to enforce"
    echo "  $0 warn online-boutique-require-resource-limits"
    echo ""
    echo "To list all constraints in cluster:"
    echo "  kubectl get K8sRequiredNonRoot,K8sRequiredResources,K8sDisallowLatestTag,K8sRequiredReadonlyFS,K8sDisallowPrivileged,K8sRequiredLabels"
    echo ""
    exit 0
fi

# Validate mode
if [[ ! "$MODE" =~ ^(enforce|dryrun|warn)$ ]]; then
    echo "❌ Invalid mode: $MODE"
    echo "Valid modes: enforce, dryrun, warn"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Switching OPA Policy Enforcement Mode"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Constraint: $CONSTRAINT_NAME"
echo "Current Mode: $(kubectl get $CONSTRAINT_KIND $CONSTRAINT_NAME -o jsonpath='{.spec.enforcementAction}' 2>/dev/null || echo 'unknown')"
echo "New Mode: $MODE"
echo ""

# Auto-detect constraint kind based on name
detect_constraint_kind() {
    local name="$1"
    case "$name" in
        *nonroot*|*non-root*)
            echo "K8sRequiredNonRoot"
            ;;
        *resource*|*limit*)
            echo "K8sRequiredResources"
            ;;
        *latest*|*tag*)
            echo "K8sDisallowLatestTag"
            ;;
        *readonly*|*read-only*|*readonlyfs*)
            echo "K8sRequiredReadonlyFS"
            ;;
        *privileged*)
            echo "K8sDisallowPrivileged"
            ;;
        *label*)
            echo "K8sRequiredLabels"
            ;;
        *)
            echo "K8sRequiredNonRoot"  # Default fallback
            ;;
    esac
}

# Auto-detect constraint kind if not explicitly set
if [ "$CONSTRAINT_NAME" != "online-boutique-must-run-nonroot" ]; then
    CONSTRAINT_KIND=$(detect_constraint_kind "$CONSTRAINT_NAME")
fi

# Check if constraint exists
if ! kubectl get $CONSTRAINT_KIND $CONSTRAINT_NAME &>/dev/null; then
    echo "❌ Constraint '$CONSTRAINT_NAME' of kind '$CONSTRAINT_KIND' not found"
    echo ""
    echo "Available constraints:"
    echo ""
    echo "Non-Root Users:"
    kubectl get K8sRequiredNonRoot 2>/dev/null | tail -n +2 || echo "  (none found)"
    echo ""
    echo "Resource Limits:"
    kubectl get K8sRequiredResources 2>/dev/null | tail -n +2 || echo "  (none found)"
    echo ""
    echo "Latest Tags:"
    kubectl get K8sDisallowLatestTag 2>/dev/null | tail -n +2 || echo "  (none found)"
    echo ""
    echo "Read-Only FS:"
    kubectl get K8sRequiredReadonlyFS 2>/dev/null | tail -n +2 || echo "  (none found)"
    echo ""
    echo "Privileged:"
    kubectl get K8sDisallowPrivileged 2>/dev/null | tail -n +2 || echo "  (none found)"
    echo ""
    echo "Labels:"
    kubectl get K8sRequiredLabels 2>/dev/null | tail -n +2 || echo "  (none found)"
    echo ""
    echo "💡 Tip: Run '$0 --help' to see all available constraint names"
    exit 1
fi

# Patch the constraint
echo "🔄 Updating enforcement mode..."
kubectl patch $CONSTRAINT_KIND $CONSTRAINT_NAME --type=merge -p "{\"spec\":{\"enforcementAction\":\"$MODE\"}}"

echo ""
echo "✅ Enforcement mode updated successfully"
echo ""
echo "Verification:"
kubectl get $CONSTRAINT_KIND $CONSTRAINT_NAME -o jsonpath='{.spec.enforcementAction}' && echo ""
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Mode: $MODE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

case "$MODE" in
    enforce)
        echo "⚠️  Policy is now BLOCKING violations"
        echo "   Pods that violate the policy will be REJECTED"
        ;;
    dryrun)
        echo "ℹ️  Policy is now in AUDIT mode"
        echo "   Violations will be REPORTED but pods will be ALLOWED"
        echo "   Check violations: kubectl describe $CONSTRAINT_KIND $CONSTRAINT_NAME"
        ;;
    warn)
        echo "ℹ️  Policy is now in WARN mode"
        echo "   Violations will generate WARNINGS but pods will be ALLOWED"
        echo "   Check events: kubectl get events"
        ;;
esac

echo ""

