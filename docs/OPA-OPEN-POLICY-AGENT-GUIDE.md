# Open Policy Agent (OPA) - Guide for k8s-platform-toolkit

## What is Open Policy Agent (OPA)?

Open Policy Agent (OPA) is a **general-purpose policy engine** that enables **unified, context-aware policy enforcement** across your entire stack. In Kubernetes, OPA is typically deployed via **Gatekeeper** as a **Validating Admission Webhook**.

---

## How OPA Works in Kubernetes

```
User/ArgoCD → kubectl apply → Kubernetes API Server
                                    ↓
                            [OPA Gatekeeper]
                            (Validates/Mutates)
                                    ↓
                            ✅ Allow or ❌ Deny
```

**OPA Gatekeeper** intercepts API requests **before** resources are created/updated and enforces policies written in **Rego** (OPA's policy language).

---

## Key Benefits for Your Cluster

### 1. **Security Hardening**
- Enforce security best practices automatically
- Prevent misconfigurations before they reach production
- Ensure compliance with security standards

### 2. **Cost Control**
- Enforce resource limits (prevent over-provisioning)
- Require resource requests/limits on all pods
- Prevent expensive resource configurations

### 3. **Governance & Compliance**
- Enforce naming conventions
- Require specific labels/annotations
- Ensure proper namespace usage

### 4. **Multi-Tenancy**
- Isolate workloads between teams
- Enforce network policies
- Control cross-namespace access

### 5. **GitOps Safety**
- Validate ArgoCD deployments before they're applied
- Prevent bad configurations from Git
- Ensure consistency across clusters

---

## Use Cases for Your Cluster

### Use Case 1: Online Boutique Security Policies

**Problem**: Ensure all microservices follow security best practices

**OPA Policies**:
```rego
# Require security contexts on all pods
# Prevent privileged containers
# Require non-root users
# Enforce read-only root filesystems
```

**Benefits**:
- All online-boutique services must have `runAsNonRoot: true`
- Prevent containers from running as root
- Enforce `allowPrivilegeEscalation: false`
- Drop all capabilities by default

**Example Policy**:
```rego
package k8srequiredlabels

violation[{"msg": msg}] {
    input.review.object.kind == "Pod"
    not input.review.object.spec.securityContext.runAsNonRoot
    msg := "All pods must run as non-root user"
}
```

---

### Use Case 2: Resource Limits Enforcement

**Problem**: Prevent resource waste and cost overruns

**OPA Policies**:
```rego
# Require CPU/memory requests and limits
# Set maximum resource limits per namespace
# Prevent resource requests > limits
```

**Benefits**:
- All pods must have resource requests/limits
- Prevent pods from consuming unlimited resources
- Control costs in performance-testing namespace
- Enforce resource quotas per namespace

**Example Policy**:
```rego
package k8srequiredresources

violation[{"msg": msg}] {
    input.review.object.kind == "Pod"
    container := input.review.object.spec.containers[_]
    not container.resources.requests.cpu
    msg := "All containers must have CPU requests"
}
```

---

### Use Case 3: Performance Testing Namespace Protection

**Problem**: Prevent accidental resource exhaustion from performance tests

**OPA Policies**:
```rego
# Limit k6 test job resources
# Prevent too many concurrent tests
# Require proper labels on test jobs
```

**Benefits**:
- Limit k6 test CPU/memory to prevent cluster overload
- Prevent running multiple stress tests simultaneously
- Ensure test jobs have proper cleanup (TTL)
- Require test jobs to have proper labels

**Example Policy**:
```rego
package k6testlimits

violation[{"msg": msg}] {
    input.review.object.kind == "Job"
    input.review.object.metadata.namespace == "performance-testing"
    input.review.object.spec.template.spec.containers[_].resources.limits.cpu > "2000m"
    msg := "k6 test jobs cannot exceed 2000m CPU limit"
}
```

---

### Use Case 4: ArgoCD Application Validation

**Problem**: Ensure ArgoCD applications follow GitOps standards

**OPA Policies**:
```rego
# Require ArgoCD apps to have sync policies
# Enforce namespace restrictions
# Require proper source repository
```

**Benefits**:
- All ArgoCD apps must have automated sync enabled
- Prevent deploying to wrong namespaces
- Ensure apps use correct Git repository
- Require proper targetRevision (prevent deploying from wrong branch)

**Example Policy**:
```rego
package argocdvalidation

violation[{"msg": msg}] {
    input.review.object.kind == "Application"
    input.review.object.spec.source.repoURL != "https://github.com/Lforlinux/k8s-platform-toolkit.git"
    msg := "ArgoCD apps must use the correct repository"
}
```

---

### Use Case 5: Image Security

**Problem**: Prevent using untrusted or outdated container images

**OPA Policies**:
```rego
# Require images from approved registries
# Block images with "latest" tag
# Require image scanning/vulnerability checks
```

**Benefits**:
- Only allow images from approved registries (e.g., Docker Hub, GCR)
- Prevent using `:latest` tags (require specific versions)
- Enforce image pull policies
- Block known vulnerable images

**Example Policy**:
```rego
package imagevalidation

violation[{"msg": msg}] {
    input.review.object.kind == "Pod"
    container := input.review.object.spec.containers[_]
    endswith(container.image, ":latest")
    msg := "Cannot use 'latest' tag. Use specific version tags."
}
```

---

### Use Case 6: Network Policy Enforcement

**Problem**: Ensure proper network isolation between services

**OPA Policies**:
```rego
# Require NetworkPolicies for production namespaces
# Enforce ingress/egress rules
# Prevent public exposure of internal services
```

**Benefits**:
- Require NetworkPolicies for online-boutique namespace
- Prevent services from accessing unauthorized resources
- Enforce least-privilege network access
- Block unnecessary external egress

---

### Use Case 7: Monitoring & Observability Requirements

**Problem**: Ensure all services expose metrics for monitoring

**OPA Policies**:
```rego
# Require prometheus.io/scrape annotations
# Enforce proper service labels
# Require health check endpoints
```

**Benefits**:
- All services must have Prometheus scraping annotations
- Ensure proper service discovery labels
- Require readiness/liveness probes
- Enforce consistent labeling for Grafana dashboards

---

### Use Case 8: Namespace Isolation

**Problem**: Prevent cross-namespace resource access

**OPA Policies**:
```rego
# Prevent pods from accessing secrets in other namespaces
# Block cross-namespace service account usage
# Enforce namespace-specific resource quotas
```

**Benefits**:
- online-boutique services can't access monitoring secrets
- performance-testing can't access production resources
- Enforce proper namespace boundaries
- Prevent privilege escalation via cross-namespace access

---

## OPA Gatekeeper vs. Native Kubernetes Policies

| Feature | OPA Gatekeeper | Native Kubernetes |
|---------|----------------|-------------------|
| **Flexibility** | ✅ Highly flexible (Rego language) | ❌ Limited to built-in policies |
| **Complex Logic** | ✅ Supports complex conditions | ❌ Basic validation only |
| **Policy Reuse** | ✅ Share policies across clusters | ❌ Cluster-specific |
| **Policy Testing** | ✅ Unit test policies | ❌ No testing framework |
| **Multi-Resource** | ✅ Validate across resources | ❌ Single resource only |
| **Learning Curve** | ⚠️ Requires learning Rego | ✅ Uses YAML |

---

## Implementation Approach

### Phase 1: Basic Security (Start Here)
1. **Install OPA Gatekeeper**
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml
   ```

2. **Deploy Common Policies**
   - Require security contexts
   - Enforce resource limits
   - Block privileged containers

### Phase 2: Application-Specific
3. **Online Boutique Policies**
   - Enforce gRPC service requirements
   - Require proper service accounts
   - Validate service mesh annotations

4. **Performance Testing Policies**
   - Limit k6 test resources
   - Require proper test labels
   - Enforce cleanup policies

### Phase 3: Advanced Governance
5. **ArgoCD Integration**
   - Validate ArgoCD applications
   - Enforce GitOps standards
   - Require proper sync policies

6. **Multi-Cluster Policies**
   - Ensure consistency across clusters
   - Enforce cluster-specific rules
   - Share policies via Git

---

## Example Policies for Your Cluster

### Policy 1: Require Resource Limits
```rego
package k8srequiredresources

violation[{"msg": msg}] {
    input.review.object.kind == "Pod"
    container := input.review.object.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("Container %v must have memory limits", [container.name])
}
```

### Policy 2: Block Privileged Containers
```rego
package k8sblockprivileged

violation[{"msg": msg}] {
    input.review.object.kind == "Pod"
    container := input.review.object.spec.containers[_]
    container.securityContext.privileged == true
    msg := sprintf("Container %v cannot run in privileged mode", [container.name])
}
```

### Policy 3: Require Non-Root Users
```rego
package k8srequirednonroot

violation[{"msg": msg}] {
    input.review.object.kind == "Pod"
    not input.review.object.spec.securityContext.runAsNonRoot
    msg := "All pods must run as non-root user"
}
```

### Policy 4: Limit k6 Test Resources
```rego
package k6testlimits

violation[{"msg": msg}] {
    input.review.object.kind == "Job"
    input.review.object.metadata.namespace == "performance-testing"
    container := input.review.object.spec.template.spec.containers[_]
    container.resources.limits.cpu > "2000m"
    msg := "k6 test jobs cannot exceed 2000m CPU limit"
}
```

---

## Integration with Your Stack

### ArgoCD Integration
- OPA validates resources **before** ArgoCD syncs them
- Failed policies prevent bad configurations from Git
- Policies are version-controlled alongside manifests

### Monitoring Integration
- OPA metrics exposed to Prometheus
- Track policy violations in Grafana
- Alert on policy failures

### CI/CD Integration
- Test policies in CI before deployment
- Validate manifests before Git commit
- Prevent policy violations early

---

## Recommended Next Steps

1. **Start Small**: Deploy OPA Gatekeeper and test with one simple policy
2. **Monitor Impact**: Track policy violations and adjust policies
3. **Expand Gradually**: Add more policies as you identify needs
4. **Document Policies**: Keep policy documentation in Git
5. **Test Policies**: Use OPA's testing framework before deploying

---

## Resources

- **OPA Documentation**: https://www.openpolicyagent.org/docs/latest/
- **Gatekeeper**: https://open-policy-agent.github.io/gatekeeper/
- **Rego Language**: https://www.openpolicyagent.org/docs/latest/policy-language/
- **Policy Library**: https://github.com/open-policy-agent/gatekeeper-library

---

## Summary

**OPA Benefits for Your Cluster**:
- ✅ **Security**: Enforce security best practices automatically
- ✅ **Cost Control**: Prevent resource waste
- ✅ **Compliance**: Ensure consistent configurations
- ✅ **GitOps Safety**: Validate ArgoCD deployments
- ✅ **Multi-Tenancy**: Isolate workloads properly

**Best Use Cases**:
1. Security hardening (non-root, no privileged)
2. Resource limits enforcement
3. Image security (no latest tags)
4. Namespace isolation
5. ArgoCD application validation

**Start With**: Basic security policies (non-root, resource limits) → Expand to application-specific rules → Add advanced governance

