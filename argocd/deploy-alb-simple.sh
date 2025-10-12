#!/bin/bash

# Simple ArgoCD ALB Deployment Script
# This script deploys ArgoCD with ALB without requiring AWS CLI configuration

set -e

echo "🚀 Deploying ArgoCD with ALB (Simple Version)..."
echo ""

# Check if ArgoCD is running
echo "🔍 Checking ArgoCD status..."
if ! kubectl get deployment argocd-server -n argocd >/dev/null 2>&1; then
    echo "❌ ArgoCD is not installed. Please run ./install-argocd.sh first"
    exit 1
fi

echo "✅ ArgoCD is running"
echo ""

# Deploy AWS Load Balancer Controller
echo "📦 Deploying AWS Load Balancer Controller..."
echo "⚠️  Note: You'll need to update the VPC ID in alb-controller.yaml"
kubectl apply -f alb-controller.yaml

# Wait for controller to be ready
echo "⏳ Waiting for AWS Load Balancer Controller to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/aws-load-balancer-controller -n kube-system

# Update ArgoCD configuration for ALB
echo "🔧 Updating ArgoCD configuration for ALB..."
kubectl apply -f argocd-config-alb.yaml
kubectl apply -f argocd-service-alb.yaml

# Restart ArgoCD server to pick up new configuration
echo "🔄 Restarting ArgoCD server..."
kubectl rollout restart deployment/argocd-server -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Deploy ALB Ingress
echo "🌐 Deploying ALB Ingress..."
echo "⚠️  Note: You'll need to update the certificate ARN and domain in alb-ingress.yaml"
kubectl apply -f alb-ingress.yaml

echo "✅ ALB deployment initiated!"
echo ""
echo "📋 Next Steps:"
echo "   1. Update VPC ID in alb-controller.yaml (line 275)"
echo "   2. Update certificate ARN in alb-ingress.yaml (line 20)"
echo "   3. Update domain name in alb-ingress.yaml (line 30)"
echo "   4. Wait 2-3 minutes for ALB to be provisioned"
echo ""
echo "🔍 Check ALB Status:"
echo "   kubectl get ingress argocd-alb-ingress -n argocd"
echo "   kubectl describe ingress argocd-alb-ingress -n argocd"
echo ""
echo "🌐 Get ALB DNS Name:"
echo "   kubectl get ingress argocd-alb-ingress -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
echo ""
echo "🔑 Get ArgoCD Admin Password:"
echo "   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
