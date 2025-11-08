#!/bin/sh

# Script to set Online-Boutique dashboard as default home dashboard
# This runs as an initContainer or sidecar to configure Grafana

set -e

GRAFANA_URL="http://localhost:3000"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin123"

# Wait for Grafana to be ready
echo "Waiting for Grafana to be ready..."
for i in $(seq 1 60); do
    if curl -s -f "${GRAFANA_URL}/api/health" > /dev/null 2>&1; then
        echo "Grafana is ready!"
        break
    fi
    echo "Waiting... ($i/60)"
    sleep 2
done

# Wait a bit more for dashboards to be discovered
echo "Waiting for dashboards to be discovered..."
sleep 20

# Find the Online-Boutique dashboard
echo "Searching for Online-Boutique dashboard..."
DASHBOARD_UID="Online-Boutique"

# Try to get the dashboard
DASHBOARD_RESPONSE=$(curl -s -X GET "${GRAFANA_URL}/api/dashboards/uid/${DASHBOARD_UID}" \
    -u "${ADMIN_USER}:${ADMIN_PASSWORD}" \
    -H "Content-Type: application/json" 2>/dev/null || echo "{}")

if echo "$DASHBOARD_RESPONSE" | grep -q "dashboard"; then
    echo "Dashboard found! Setting as default home dashboard..."
    
    # Get the dashboard ID
    DASHBOARD_ID=$(echo "$DASHBOARD_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
    
    if [ -n "$DASHBOARD_ID" ]; then
        # Update organization preferences to set home dashboard
        curl -s -X PUT "${GRAFANA_URL}/api/org/preferences" \
            -u "${ADMIN_USER}:${ADMIN_PASSWORD}" \
            -H "Content-Type: application/json" \
            -d "{\"homeDashboardId\": ${DASHBOARD_ID}}" > /dev/null
        
        echo "Default home dashboard set to Online-Boutique (ID: ${DASHBOARD_ID})"
    else
        echo "Could not extract dashboard ID"
    fi
else
    echo "Dashboard not found yet. It may need more time to be discovered."
    echo "Response: $DASHBOARD_RESPONSE"
fi


