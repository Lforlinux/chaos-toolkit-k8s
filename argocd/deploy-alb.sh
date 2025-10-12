#!/bin/bash

# ArgoCD ALB Deployment Script
# This script deploys ArgoCD with Application Load Balancer (ALB) for external access

set -e

# Configuration variables
CLUSTER_NAME=${CLUSTER_NAME:-"your-cluster-name"}
AWS_REGION=${AWS_REGION:-"eu-west-1"}
VPC_ID=${VPC_ID:-"vpc-xxxxxxxxx"}
DOMAIN_NAME=${DOMAIN_NAME:-"argocd.yourdomain.com"}
CERT_ARN=${CERT_ARN:-"arn:aws:acm:eu-west-1:YOUR_ACCOUNT_ID:certificate/YOUR_CERT_ID"}

echo "🚀 Deploying ArgoCD with ALB..."
echo "📋 Configuration:"
echo "   Cluster Name: $CLUSTER_NAME"
echo "   AWS Region: $AWS_REGION"
echo "   VPC ID: $VPC_ID"
echo "   Domain: $DOMAIN_NAME"
echo "   Certificate ARN: $CERT_ARN"
echo ""

# Check if required tools are installed
echo "🔍 Checking prerequisites..."
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed"
    exit 1
fi

# Check AWS credentials
echo "🔐 Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured"
    exit 1
fi

# Check if ArgoCD is already installed
echo "🔍 Checking ArgoCD installation..."
if ! kubectl get deployment argocd-server -n argocd >/dev/null 2>&1; then
    echo "❌ ArgoCD is not installed. Please run ./install-argocd.sh first"
    exit 1
fi

# Update configuration files with actual values
echo "📝 Updating configuration files..."
sed -i.bak "s/YOUR_CLUSTER_NAME/$CLUSTER_NAME/g" alb-controller.yaml
sed -i.bak "s/vpc-xxxxxxxxx/$VPC_ID/g" alb-controller.yaml
sed -i.bak "s/eu-west-1/$AWS_REGION/g" alb-controller.yaml
sed -i.bak "s/argocd.yourdomain.com/$DOMAIN_NAME/g" alb-ingress.yaml
sed -i.bak "s/arn:aws:acm:eu-west-1:YOUR_ACCOUNT_ID:certificate\/YOUR_CERT_ID/$CERT_ARN/g" alb-ingress.yaml
sed -i.bak "s/argocd.yourdomain.com/$DOMAIN_NAME/g" argocd-config-alb.yaml

# Deploy AWS Load Balancer Controller
echo "📦 Deploying AWS Load Balancer Controller..."
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
kubectl apply -f alb-ingress.yaml

# Wait for ALB to be provisioned
echo "⏳ Waiting for ALB to be provisioned..."
echo "   This may take 2-3 minutes..."

# Get ALB DNS name
ALB_DNS=""
while [ -z "$ALB_DNS" ]; do
    ALB_DNS=$(kubectl get ingress argocd-alb-ingress -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ -z "$ALB_DNS" ]; then
        echo "   Waiting for ALB DNS name..."
        sleep 10
    fi
done

echo "✅ ALB provisioned successfully!"
echo ""

# Get ArgoCD admin password
echo "🔑 Getting ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "🎉 ArgoCD ALB deployment completed!"
echo ""
echo "🌐 Access Information:"
echo "   ALB DNS Name: $ALB_DNS"
echo "   Domain: $DOMAIN_NAME"
echo "   URL: https://$DOMAIN_NAME"
echo ""
echo "👤 Login credentials:"
echo "   Username: admin"
echo "   Password: $ARGOCD_PASSWORD"
echo ""
echo "📋 Next Steps:"
echo "   1. Update your DNS to point $DOMAIN_NAME to $ALB_DNS"
echo "   2. Wait for DNS propagation (5-10 minutes)"
echo "   3. Access ArgoCD at https://$DOMAIN_NAME"
echo ""
echo "🔧 Troubleshooting:"
echo "   Check ALB status: kubectl get ingress argocd-alb-ingress -n argocd"
echo "   Check ALB events: kubectl describe ingress argocd-alb-ingress -n argocd"
echo "   Check ArgoCD logs: kubectl logs -n argocd deployment/argocd-server"
echo ""
echo "📚 Documentation:"
echo "   ALB Ingress: https://kubernetes-sigs.github.io/aws-load-balancer-controller/"
echo "   ArgoCD: https://argo-cd.readthedocs.io/"
