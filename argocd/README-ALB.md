# ArgoCD with Application Load Balancer (ALB)

This guide explains how to deploy ArgoCD with an AWS Application Load Balancer (ALB) for external access.

## 📋 Prerequisites

### AWS Requirements
- AWS CLI configured with appropriate permissions
- EKS cluster running
- VPC with public subnets
- SSL/TLS certificate in AWS Certificate Manager (ACM)
- Domain name for ArgoCD access

### Required Permissions
Your AWS user/role needs the following permissions:
- `elasticloadbalancing:*`
- `ec2:DescribeVpcs`
- `ec2:DescribeSubnets`
- `ec2:DescribeSecurityGroups`
- `acm:ListCertificates`
- `acm:DescribeCertificate`
- `iam:CreateServiceLinkedRole`

## 🚀 Quick Deployment

### 1. Set Environment Variables

```bash
export CLUSTER_NAME="your-cluster-name"
export AWS_REGION="eu-west-1"
export VPC_ID="vpc-xxxxxxxxx"
export DOMAIN_NAME="argocd.yourdomain.com"
export CERT_ARN="arn:aws:acm:eu-west-1:YOUR_ACCOUNT_ID:certificate/YOUR_CERT_ID"
```

### 2. Deploy ArgoCD with ALB

```bash
./argocd/deploy-alb.sh
```

## 📁 Files Overview

### Core ALB Files
- `alb-controller.yaml` - AWS Load Balancer Controller deployment
- `alb-ingress.yaml` - ALB Ingress configuration for ArgoCD
- `argocd-service-alb.yaml` - ArgoCD service configuration for ALB
- `argocd-config-alb.yaml` - ArgoCD configuration for external access
- `deploy-alb.sh` - Automated deployment script

## 🔧 Configuration Details

### ALB Ingress Configuration

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-alb-ingress
  namespace: argocd
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/backend-protocol: HTTPS
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    alb.ingress.kubernetes.io/certificate-arn: YOUR_CERT_ARN
```

### Key Annotations Explained

- `scheme: internet-facing` - Creates a public ALB
- `target-type: ip` - Routes traffic to pod IPs
- `backend-protocol: HTTPS` - Uses HTTPS for backend communication
- `ssl-redirect: '443'` - Redirects HTTP to HTTPS
- `certificate-arn` - SSL certificate for HTTPS

## 🌐 DNS Configuration

After deployment, you'll get an ALB DNS name. Configure your DNS:

```bash
# Get ALB DNS name
kubectl get ingress argocd-alb-ingress -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Create CNAME record in your DNS provider
# Point your domain to the ALB DNS name
```

## 🔍 Troubleshooting

### Check ALB Status
```bash
kubectl get ingress argocd-alb-ingress -n argocd
kubectl describe ingress argocd-alb-ingress -n argocd
```

### Check AWS Load Balancer Controller
```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

### Check ArgoCD Status
```bash
kubectl get pods -n argocd
kubectl logs -n argocd deployment/argocd-server
```

### Common Issues

#### 1. ALB Not Created
- Check AWS Load Balancer Controller logs
- Verify VPC and subnet configuration
- Ensure proper IAM permissions

#### 2. SSL Certificate Issues
- Verify certificate ARN is correct
- Ensure certificate is in the same region as ALB
- Check certificate status in AWS Console

#### 3. DNS Resolution Issues
- Verify DNS CNAME record is correct
- Wait for DNS propagation (5-10 minutes)
- Test with `nslookup` or `dig`

#### 4. ArgoCD Not Accessible
- Check ArgoCD server logs
- Verify service endpoints
- Test internal connectivity

## 🔒 Security Considerations

### Network Security
- ALB is internet-facing (consider using internal ALB for private access)
- SSL/TLS termination at ALB
- Backend communication over HTTPS

### Access Control
- ArgoCD RBAC is still enforced
- Consider using OIDC for authentication
- Implement proper network policies

### SSL/TLS
- Use AWS Certificate Manager for SSL certificates
- Enable SSL redirect
- Use strong cipher suites

## 📊 Monitoring

### ALB Metrics
- Available in CloudWatch
- Monitor request count, latency, error rates
- Set up alarms for critical metrics

### ArgoCD Metrics
- Available at `/metrics` endpoint
- Monitor application sync status
- Track deployment success rates

## 🔄 Updates and Maintenance

### Update AWS Load Balancer Controller
```bash
kubectl apply -f alb-controller.yaml
```

### Update ArgoCD Configuration
```bash
kubectl apply -f argocd-config-alb.yaml
kubectl rollout restart deployment/argocd-server -n argocd
```

### Scale ArgoCD
```bash
kubectl scale deployment argocd-server -n argocd --replicas=3
```

## 📚 Additional Resources

- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [EKS Ingress](https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html)
- [AWS Certificate Manager](https://docs.aws.amazon.com/acm/)

## 🎯 Best Practices

1. **Use Internal ALB** for private access when possible
2. **Implement proper RBAC** for ArgoCD access
3. **Monitor ALB metrics** in CloudWatch
4. **Use AWS WAF** for additional security
5. **Regular security updates** for ArgoCD and ALB controller
6. **Backup ArgoCD configuration** regularly
7. **Use GitOps** for all configuration changes
