#!/bin/bash

# Script to check service protocols (HTTP vs gRPC) in Online Boutique

set -e

NAMESPACE="online-boutique"

echo "🔍 Checking Service Protocols in Online Boutique"
echo "=================================================="
echo ""

echo "📋 Services and their protocols:"
echo ""

# Get all services and check their port names
kubectl get svc -n $NAMESPACE -o json | jq -r '.items[] | "\(.metadata.name)|\(.spec.ports[0].name // "unnamed")|\(.spec.ports[0].port)"' | while IFS='|' read -r name port_name port; do
    protocol="❓ Unknown"
    if [ "$port_name" = "grpc" ]; then
        protocol="🔵 gRPC"
    elif [ "$port_name" = "http" ]; then
        protocol="🟢 HTTP"
    elif [ "$port_name" = "tcp" ] || [ -z "$port_name" ]; then
        # Check common ports to infer protocol
        if [ "$port" = "80" ] || [ "$port" = "8080" ] || [ "$port" = "3000" ]; then
            protocol="🟢 HTTP (inferred)"
        elif [ "$port" = "50051" ] || [ "$port" = "3550" ]; then
            protocol="🔵 gRPC (inferred)"
        else
            protocol="❓ Unknown (port: $port)"
        fi
    fi
    
    printf "%-30s %-20s Port: %-6s %s\n" "$name" "$protocol" "$port" "$port_name"
done

echo ""
echo "📊 Summary:"
echo ""

# Count protocols
HTTP_COUNT=$(kubectl get svc -n $NAMESPACE -o json | jq -r '.items[] | select(.spec.ports[0].name == "http") | .metadata.name' | wc -l | tr -d ' ')
GRPC_COUNT=$(kubectl get svc -n $NAMESPACE -o json | jq -r '.items[] | select(.spec.ports[0].name == "grpc") | .metadata.name' | wc -l | tr -d ' ')

echo "🟢 HTTP Services: $HTTP_COUNT"
echo "🔵 gRPC Services: $GRPC_COUNT"
echo ""
echo "💡 To see detailed port information:"
echo "   kubectl get svc <service-name> -n $NAMESPACE -o yaml | grep -A 5 'ports:'"
echo ""
echo "💡 To see all services with port names:"
echo "   kubectl get svc -n $NAMESPACE -o custom-columns=NAME:.metadata.name,PORT-NAME:.spec.ports[0].name,PORT:.spec.ports[0].port"

