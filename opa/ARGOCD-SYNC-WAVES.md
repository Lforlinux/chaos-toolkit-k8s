# ArgoCD Sync Waves for OPA Policies

## Problem

ArgoCD applies resources in parallel by default, which causes ConstraintTemplates to be applied before Gatekeeper CRDs exist, resulting in "unknown kind" errors.

## Solution

Using ArgoCD sync waves to ensure proper ordering:

1. **Wave -1**: Gatekeeper resources (CRDs, controller, RBAC)
2. **Wave 0**: ConstraintTemplates (policy definitions)
3. **Wave 1**: Constraints (policy enforcement)

## How It Works

Sync waves are added via Kustomize patches in:
- `opa/kustomization.yaml` - Adds wave -1 to Gatekeeper resources
- `opa/k8s-policy-manifest/kustomization.yaml` - Adds wave 0 to ConstraintTemplates, wave 1 to Constraints

ArgoCD respects these annotations and applies resources in wave order.

## Verification

After syncing in ArgoCD, resources should be applied in this order:

1. ✅ Gatekeeper CRDs (wave -1)
2. ✅ Gatekeeper controller (wave -1)
3. ✅ ConstraintTemplates (wave 0)
4. ✅ Constraints (wave 1)

## Troubleshooting

If sync still fails:

1. Check sync waves are applied:
   ```bash
   kubectl kustomize opa/ | grep "argocd.argoproj.io/sync-wave"
   ```

2. Manually sync in ArgoCD UI:
   - Click "SYNC" button
   - Watch the sync order in the UI

3. Check for CRD readiness:
   ```bash
   kubectl get crd constrainttemplates.templates.gatekeeper.sh
   kubectl wait --for condition=established crd/constrainttemplates.templates.gatekeeper.sh --timeout=60s
   ```

