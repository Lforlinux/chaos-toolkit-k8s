# 🔥 Chaos Engineering with ArgoCD

This directory contains chaos engineering experiments using the [Chaos Toolkit](https://github.com/chaostoolkit/chaostoolkit) integrated with ArgoCD for GitOps-based chaos testing.

## 📁 Directory Structure

```
chaos/
├── experiments/                    # Chaos experiment definitions
│   ├── stop-random-pod.json       # Pod termination experiment
│   ├── modify-deployment.json     # Resource constraint experiment
│   └── network-chaos.json         # Network disruption experiment
├── chaos-runner.yaml              # Kubernetes Job for running experiments
├── chaos-experiment-selector.yaml # Web UI for experiment selection
├── chaos-api-server.yaml          # API server for experiment execution
└── README-Chaos-Engineering.md    # This file
```

## 🎯 Available Chaos Experiments

### 1. **Stop Random Pod** 🔥
- **Category**: Pod Chaos
- **Risk Level**: Medium
- **Duration**: 2 minutes
- **Description**: Randomly terminates a pod to test pod restart resilience
- **What it tests**: Kubernetes pod restart capabilities, application recovery

### 2. **Modify Deployment Resources** ⚡
- **Category**: Resource Chaos
- **Risk Level**: Low
- **Duration**: 3 minutes
- **Description**: Reduces CPU/Memory limits and scales down deployment
- **What it tests**: Application behavior under resource constraints

### 3. **Network Latency & Packet Loss** 🌐
- **Category**: Network Chaos
- **Risk Level**: High
- **Duration**: 2 minutes
- **Description**: Introduces network latency and packet loss
- **What it tests**: Service communication resilience, timeout handling

## 🚀 How to Use

### **Via ArgoCD UI (Recommended)**

1. **Access ArgoCD**: Open your ArgoCD UI
2. **Navigate to Applications**: Click on "Applications"
3. **Find Chaos Experiments**: Look for "chaos-experiments" application
4. **Sync Application**: Click "SYNC" to deploy chaos infrastructure
5. **Access Chaos UI**: Port-forward to chaos-selector-ui service:
   ```bash
   kubectl port-forward svc/chaos-selector-ui 8080:80
   ```
6. **Run Experiments**: Open http://localhost:8080 and click experiment buttons

### **Via kubectl (Direct)**

```bash
# Deploy chaos infrastructure
kubectl apply -f chaos/

# Access chaos experiment UI
kubectl port-forward svc/chaos-selector-ui 8080:80

# Open browser to http://localhost:8080
```

## 🔧 Technical Details

### **Chaos Toolkit Integration**

The experiments use the [Chaos Toolkit](https://github.com/chaostoolkit/chaostoolkit) with the following extensions:
- `chaostoolkit-kubernetes`: For Kubernetes-specific chaos actions
- `chaostoolkit-prometheus`: For monitoring integration

### **Experiment Structure**

Each experiment follows the Chaos Toolkit format:
```json
{
  "version": "1.0.0",
  "title": "Experiment Name",
  "description": "What this experiment does",
  "steady-state-hypothesis": {
    "title": "Expected state before experiment",
    "probes": [...]
  },
  "method": [
    {
      "type": "action",
      "name": "chaos-action",
      "provider": {...}
    }
  ],
  "rollbacks": [
    {
      "type": "action",
      "name": "restore-state",
      "provider": {...}
    }
  ]
}
```

### **ArgoCD Integration**

- **Application**: `chaos-experiments` in ArgoCD
- **Source**: Points to `chaos/` directory in your Git repository
- **Sync Policy**: Automated with self-heal enabled
- **Namespace**: `default`

## 🎮 Experiment Categories

### **Pod Chaos** 🔥
- Pod termination
- Pod resource constraints
- Pod network isolation

### **Resource Chaos** ⚡
- CPU/Memory limits
- Disk space constraints
- Deployment scaling

### **Network Chaos** 🌐
- Latency injection
- Packet loss
- Network partitioning

## 📊 Monitoring Integration

The chaos experiments integrate with your existing monitoring stack:

- **Prometheus**: Metrics collection during experiments
- **Grafana**: Visualization of chaos experiment results
- **ArgoCD**: Deployment status and experiment logs

## 🛡️ Safety Features

### **Rollback Mechanisms**
- Automatic rollback after experiment completion
- Manual rollback via ArgoCD UI
- Kubernetes native rollback capabilities

### **Risk Management**
- Risk level indicators (Low/Medium/High)
- Experiment duration limits
- Resource isolation

### **Monitoring**
- Real-time experiment status
- Detailed logging
- Integration with existing monitoring

## 🔍 Troubleshooting

### **Common Issues**

1. **Experiment fails to start**
   ```bash
   kubectl logs -l app=chaos-experiment
   ```

2. **Permission denied**
   ```bash
   kubectl get clusterrolebinding chaos-runner
   kubectl get serviceaccount chaos-runner -n default
   ```

3. **Chaos Toolkit not found**
   ```bash
   kubectl describe job chaos-experiment-<name>
   ```

### **Debug Commands**

```bash
# Check chaos experiment jobs
kubectl get jobs -l app=chaos-experiment

# View experiment logs
kubectl logs -l app=chaos-experiment --tail=100

# Check chaos API server
kubectl logs -l app=chaos-api

# Verify chaos experiments configmap
kubectl get configmap chaos-experiments -o yaml
```

## 📚 Learning Resources

- [Chaos Toolkit Documentation](https://docs.chaostoolkit.org/)
- [Chaos Engineering Principles](https://principlesofchaos.org/)
- [Kubernetes Chaos Engineering](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-cluster/)
- [ArgoCD GitOps](https://argo-cd.readthedocs.io/)

## 🤝 Contributing

To add new chaos experiments:

1. Create new experiment JSON file in `experiments/` directory
2. Follow Chaos Toolkit format
3. Add experiment to `chaos-experiment-selector.yaml` configmap
4. Test experiment locally
5. Commit and push to Git repository
6. ArgoCD will automatically sync the changes

## ⚠️ Important Notes

- **Production Use**: Test experiments in non-production environments first
- **Resource Limits**: Monitor cluster resources during experiments
- **Backup**: Ensure you have backups before running destructive experiments
- **Team Communication**: Inform team members before running chaos experiments
- **Monitoring**: Always monitor your applications during chaos experiments

---

**Happy Chaos Engineering! 🔥**
