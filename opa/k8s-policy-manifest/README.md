# OPA Policy Manifests

This directory contains all OPA Gatekeeper ConstraintTemplates and Constraints organized for Kustomize.

## Structure

```
k8s-policy-manifest/
├── kustomization.yaml                    # Kustomize configuration
├── constrainttemplate-*.yaml            # Policy definitions (ConstraintTemplates)
└── constraint-online-boutique-*-demo.yaml # Policy enforcement (Constraints in dryrun mode)
```

## Policies

### ConstraintTemplates (Policy Definitions)
1. `constrainttemplate-require-nonroot.yaml` - Require non-root users
2. `constrainttemplate-require-resource-limits.yaml` - Require CPU/memory limits
3. `constrainttemplate-disallow-latest-tag.yaml` - Disallow :latest tags
4. `constrainttemplate-require-readonly-fs.yaml` - Require read-only filesystem
5. `constrainttemplate-disallow-privileged.yaml` - Disallow privileged containers
6. `constrainttemplate-require-labels.yaml` - Require specific labels

### Constraints (Policy Enforcement - Demo Mode)
All constraints are in **dryrun mode** (reports violations but doesn't block):
1. `constraint-online-boutique-nonroot-demo.yaml`
2. `constraint-online-boutique-resource-limits-demo.yaml`
3. `constraint-online-boutique-latest-tag-demo.yaml`
4. `constraint-online-boutique-readonly-fs-demo.yaml`
5. `constraint-online-boutique-privileged-demo.yaml`
6. `constraint-online-boutique-required-labels-demo.yaml`

## Deployment

### Using Kustomize (Recommended)

```bash
# Deploy all policies at once
kubectl apply -k opa/k8s-policy-manifest/

# Or from the opa directory
cd opa
kubectl apply -k k8s-policy-manifest/
```

### Using Deployment Script

```bash
cd opa/deployment
./deploy-all-policies-demo.sh
```

## Enforcement Modes

All constraints in this directory are set to `enforcementAction: dryrun` (demo mode).

To switch to enforce mode:
```bash
cd opa/deployment
./switch-enforcement-mode.sh enforce <constraint-name>

# Example:
./switch-enforcement-mode.sh enforce online-boutique-must-run-nonroot
```

## Customization

To modify which policies are deployed, edit `kustomization.yaml` and add/remove resources.

## Verification

```bash
# Check all constraints
kubectl get K8sRequiredNonRoot,K8sRequiredResources,K8sDisallowLatestTag,K8sRequiredReadonlyFS,K8sDisallowPrivileged,K8sRequiredLabels

# View violations
kubectl describe K8sRequiredNonRoot online-boutique-must-run-nonroot
```

