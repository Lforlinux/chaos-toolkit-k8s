#!/bin/bash

# Deploy ArgoCD Applications via kubectl
# This is for learning purposes - in production you'd use Git repositories

set -e

echo "🚀 Deploying ArgoCD Applications via kubectl..."
echo ""

# Check if ArgoCD is running
echo "🔍 Checking ArgoCD status..."
if ! kubectl get deployment argocd-server -n argocd >/dev/null 2>&1; then
    echo "❌ ArgoCD is not installed. Please run ./install-argocd.sh first"
    exit 1
fi

echo "✅ ArgoCD is running"
echo ""

# Deploy microservices application
echo "📦 Deploying microservices application..."
kubectl apply -f microservices-app-local.yaml

# Deploy monitoring application
echo "📊 Deploying monitoring application..."
kubectl apply -f monitoring-app-local.yaml

echo ""
echo "✅ ArgoCD applications deployed successfully!"
echo ""
echo "🌐 Access ArgoCD UI:"
echo "   http://a7bdc31c3dc1d40b6a7864152748bc10-1109434892.eu-west-1.elb.amazonaws.com/applications"
echo ""
echo "👤 Login credentials:"
echo "   Username: admin"
echo "   Password: 3Whk8H7AqZ0kuXyf"
echo ""
echo "📋 What you'll see in ArgoCD UI:"
echo "   1. microservices-demo - Your microservices application"
echo "   2. monitoring-stack - Your monitoring stack (Prometheus, Grafana)"
echo ""
echo "🎯 Next Steps:"
echo "   1. Open ArgoCD UI in your browser"
echo "   2. Login with admin credentials"
echo "   3. Click on 'microservices-demo' to see your application"
echo "   4. Click 'SYNC' to deploy your microservices"
echo "   5. Click on 'monitoring-stack' to see your monitoring"
echo "   6. Click 'SYNC' to deploy your monitoring stack"
echo ""
echo "📚 Learning ArgoCD:"
echo "   - Applications show the desired state from Git"
echo "   - SYNC button applies changes to your cluster"
echo "   - You can see deployment status, logs, and events"
echo "   - ArgoCD automatically detects changes in Git"
