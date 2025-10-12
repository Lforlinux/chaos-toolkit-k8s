# Chaos Toolkit K8s - GitOps Repository

This repository contains Kubernetes manifests and configurations for a complete microservices monitoring and deployment setup using GitOps principles with ArgoCD.

## 📁 Repository Structure

```
├── application/          # Microservices demo application
├── argocd/              # ArgoCD configuration and applications
├── dashboards/          # Grafana dashboards
├── docs/               # Documentation
├── monitoring/         # Prometheus & Grafana monitoring stack
└── scripts/            # Deployment and utility scripts
```

## 🚀 Quick Start

### 1. Deploy ArgoCD
```bash
./argocd/install-argocd.sh
```

### 2. Deploy with LoadBalancer
```bash
./argocd/deploy-alb-simple.sh
```

### 3. Access ArgoCD UI
- URL: `http://your-loadbalancer-url/applications`
- Username: `admin`
- Password: (get from ArgoCD secret)

## 🎯 Applications

### Microservices Demo
- **Source:** `application/` directory
- **Namespace:** `default`
- **Description:** Complete microservices demo with frontend, backend services, and Redis

### Monitoring Stack
- **Source:** `monitoring/` directory
- **Namespace:** `monitoring`
- **Description:** Prometheus, Grafana, kube-state-metrics, and node-exporter

## 🔄 GitOps Workflow

1. **Make Changes:** Update YAML files in this repository
2. **Commit & Push:** Changes are automatically detected by ArgoCD
3. **Auto-Sync:** ArgoCD automatically syncs changes to your cluster
4. **Monitor:** Use ArgoCD UI to monitor deployment status

## 📊 Monitoring

- **Prometheus:** Metrics collection and alerting
- **Grafana:** Visualization and dashboards
- **ArgoCD:** GitOps deployment management

## 🛠️ Tools Used

- **Kubernetes:** Container orchestration
- **ArgoCD:** GitOps continuous delivery
- **Prometheus:** Metrics collection
- **Grafana:** Monitoring dashboards
- **AWS Load Balancer:** External access

## 📚 Documentation

- [ArgoCD Setup](argocd/README-ArgoCD.md)
- [ALB Configuration](argocd/README-ALB.md)
- [Monitoring Guide](docs/README-Enhanced-Monitoring.md)

## 🔧 Prerequisites

- Kubernetes cluster (EKS recommended)
- kubectl configured
- AWS CLI (for ALB setup)
- Git repository access

## 📝 License

This project is for educational and demonstration purposes.
