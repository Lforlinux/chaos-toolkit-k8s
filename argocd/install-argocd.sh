#!/bin/bash

# ArgoCD Installation Script
# This script installs ArgoCD using the official installation method

set -e

echo "🚀 Installing ArgoCD..."

# Create namespace
echo "📁 Creating ArgoCD namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
echo "📦 Installing ArgoCD components..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
echo "⏳ Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get the initial admin password
echo "🔑 Getting ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "✅ ArgoCD installation completed!"
echo ""
echo "🌐 Access ArgoCD UI:"
echo "   kubectl port-forward -n argocd svc/argocd-server 8080:443"
echo "   Then open: https://localhost:8080"
echo ""
echo "👤 Login credentials:"
echo "   Username: admin"
echo "   Password: $ARGOCD_PASSWORD"
echo ""
echo "🔧 CLI Installation:"
echo "   curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
echo "   sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd"
echo "   rm argocd-linux-amd64"
echo ""
echo "📚 Next steps:"
echo "   1. Port-forward to access UI: kubectl port-forward -n argocd svc/argocd-server 8080:443"
echo "   2. Login with admin credentials above"
echo "   3. Create applications to manage your microservices and monitoring stack"
