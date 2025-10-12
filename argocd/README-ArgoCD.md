# ArgoCD GitOps Setup

This directory contains ArgoCD configuration and deployment files for managing your Kubernetes applications using GitOps principles.

## 📁 Directory Structure

```
argocd/
├── install-argocd.sh          # ArgoCD installation script
├── deploy-applications.sh     # Application deployment script
├── app-of-apps.yaml          # App of Apps pattern configuration
├── applications/             # Application definitions
│   ├── microservices-app.yaml
│   └── monitoring-app.yaml
└── README-ArgoCD.md         # This documentation
```

## 🚀 Quick Start

### 1. Install ArgoCD

```bash
./argocd/install-argocd.sh
```

This script will:
- Create the `argocd` namespace
- Install ArgoCD components
- Display login credentials
- Provide access instructions

### 2. Access ArgoCD UI

```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

Then open: https://localhost:8080

**Default Login:**
- Username: `admin`
- Password: (displayed after installation)

### 3. Deploy Applications

```bash
./argocd/deploy-applications.sh
```

This script will:
- Create ArgoCD applications for microservices and monitoring
- Enable automated sync
- Deploy your applications

## 📊 Applications

### Microservices Demo
- **Name:** `microservices-demo`
- **Source:** `application/` directory
- **Destination:** `default` namespace
- **Features:** Automated sync, self-healing, auto-prune

### Monitoring Stack
- **Name:** `monitoring-stack`
- **Source:** `monitoring/` directory
- **Destination:** `monitoring` namespace
- **Features:** Automated sync, self-healing, auto-prune

## 🔧 ArgoCD CLI

### Installation
```bash
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

### Common Commands

```bash
# List applications
argocd app list

# Get application details
argocd app get microservices-demo

# Sync application
argocd app sync microservices-demo

# Delete application
argocd app delete microservices-demo

# Get application logs
argocd app logs microservices-demo

# Get application events
argocd app events microservices-demo
```

## 🔄 GitOps Workflow

1. **Make Changes:** Update YAML files in your repository
2. **Commit & Push:** Changes are automatically detected by ArgoCD
3. **Auto-Sync:** ArgoCD automatically syncs changes to your cluster
4. **Monitor:** Use ArgoCD UI or CLI to monitor deployment status

## 🛠️ Configuration

### Application Settings

Each application is configured with:
- **Automated Sync:** Automatically syncs when changes are detected
- **Self-Healing:** Automatically corrects drift
- **Auto-Prune:** Removes resources that are no longer defined
- **Revision History:** Keeps 10 revisions for rollback capability

### RBAC Configuration

ArgoCD is configured with:
- **Default Role:** `readonly` for all users
- **Admin Role:** Full access for `argocd-admins` group
- **Policy:** Defined in `argocd-rbac-cm` ConfigMap

## 🔍 Troubleshooting

### Check ArgoCD Status
```bash
kubectl get pods -n argocd
kubectl get svc -n argocd
```

### View Application Status
```bash
argocd app list
argocd app get <app-name>
```

### Check Application Logs
```bash
argocd app logs <app-name>
kubectl logs -n argocd deployment/argocd-server
```

### Reset Admin Password
```bash
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {
    "admin.password": "$2a$10$rRyBsGSHK6.uc8fntPwVFOBqQyHshURWk0X7EqJ0fO2/0uSxUlBMS",
    "admin.passwordMtime": "'$(date +%Y-%m-%dT%H:%M:%S)'"
  }}'
```

## 📚 Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://www.gitops.tech/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/operator-manual/)

## 🎯 Next Steps

1. **Configure Git Repository:** Update repository URLs in application definitions
2. **Set Up Webhooks:** Configure Git webhooks for faster sync
3. **Add More Applications:** Create additional application definitions
4. **Configure Notifications:** Set up Slack/email notifications
5. **Implement RBAC:** Configure proper user roles and permissions
