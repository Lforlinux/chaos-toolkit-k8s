#!/bin/bash

# ArgoCD Applications Deployment Script
# This script deploys applications to ArgoCD

set -e

echo "🚀 Deploying applications to ArgoCD..."

# Check if ArgoCD is running
echo "🔍 Checking ArgoCD status..."
if ! kubectl get deployment argocd-server -n argocd >/dev/null 2>&1; then
    echo "❌ ArgoCD is not installed. Please run ./install-argocd.sh first"
    exit 1
fi

# Wait for ArgoCD to be ready
echo "⏳ Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Port forward ArgoCD server
echo "🌐 Setting up port forwarding for ArgoCD..."
kubectl port-forward -n argocd svc/argocd-server 8080:443 &
PORT_FORWARD_PID=$!

# Wait for port forward to be ready
sleep 5

# Get admin password
echo "🔑 Getting ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Install ArgoCD CLI if not present
if ! command -v argocd &> /dev/null; then
    echo "📥 Installing ArgoCD CLI..."
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    chmod +x argocd-linux-amd64
    sudo mv argocd-linux-amd64 /usr/local/bin/argocd
fi

# Login to ArgoCD
echo "🔐 Logging into ArgoCD..."
argocd login localhost:8080 --username admin --password "$ARGOCD_PASSWORD" --insecure

# Create applications
echo "📦 Creating ArgoCD applications..."

# Create microservices application
echo "  - Creating microservices-demo application..."
argocd app create microservices-demo \
  --repo https://github.com/your-org/k8s-sre.git \
  --path application \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy automated \
  --auto-prune \
  --self-heal

# Create monitoring application
echo "  - Creating monitoring-stack application..."
argocd app create monitoring-stack \
  --repo https://github.com/your-org/k8s-sre.git \
  --path monitoring \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace monitoring \
  --sync-policy automated \
  --auto-prune \
  --self-heal

# Sync applications
echo "🔄 Syncing applications..."
argocd app sync microservices-demo
argocd app sync monitoring-stack

# Clean up port forward
kill $PORT_FORWARD_PID

echo "✅ ArgoCD applications deployed successfully!"
echo ""
echo "🌐 Access ArgoCD UI:"
echo "   kubectl port-forward -n argocd svc/argocd-server 8080:443"
echo "   Then open: https://localhost:8080"
echo ""
echo "👤 Login credentials:"
echo "   Username: admin"
echo "   Password: $ARGOCD_PASSWORD"
echo ""
echo "📊 View applications:"
echo "   argocd app list"
echo "   argocd app get microservices-demo"
echo "   argocd app get monitoring-stack"
