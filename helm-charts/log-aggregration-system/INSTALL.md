# Quick Installation Guide

## Prerequisites

- Kubernetes cluster (v1.19+)
- Helm 3.0+
- kubectl configured
- At least 4GB RAM available
- Persistent Volume provisioner (optional, for data persistence)

## Installation Steps

### 1. Navigate to the chart directory

```bash
cd helm/log-aggregration-system
```

### 2. Validate the chart

```bash
# Lint the chart
helm lint .

# Test template rendering
helm template test-release . --dry-run
```

### 3. Install the chart

```bash
# Create namespace
kubectl create namespace logging

# Install with default values
helm install log-aggregation . --namespace logging

# OR install with custom values
helm install log-aggregation . --namespace logging \
  --set grafana.adminPassword=your-secure-password \
  --set persistence.elasticsearch.size=20Gi \
  --set replicaCount=2
```

### 4. Verify deployment

```bash
# Check pod status
kubectl get pods -n logging

# Wait for pod to be ready (may take 1-2 minutes for Elasticsearch)
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=log-aggregration-system -n logging --timeout=300s

# Check services
kubectl get svc -n logging
```

### 5. Access the services

```bash
# Get pod name
export POD_NAME=$(kubectl get pods -n logging -l "app.kubernetes.io/name=log-aggregration-system" -o jsonpath="{.items[0].metadata.name}")

# Port forward all services
kubectl port-forward -n logging $POD_NAME 8000:8000 &  # Log Aggregator API
kubectl port-forward -n logging $POD_NAME 3000:3000 &  # Grafana
kubectl port-forward -n logging $POD_NAME 9090:9090 &  # Prometheus
kubectl port-forward -n logging $POD_NAME 16686:16686 & # Jaeger
kubectl port-forward -n logging $POD_NAME 9200:9200 &  # Elasticsearch
```

Then access:
- **Log Aggregator API**: http://localhost:8000/docs
- **Grafana**: http://localhost:3000 (admin / changeme)
- **Prometheus**: http://localhost:9090
- **Jaeger**: http://localhost:16686
- **Elasticsearch**: http://localhost:9200

### 6. Test the system

```bash
# Ingest a test log
curl -X POST http://localhost:8000/api/v1/logs/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "logs": [
      {
        "timestamp": "2025-12-30T10:00:00Z",
        "level": "INFO",
        "message": "Test log from installation",
        "source": "quickstart"
      }
    ]
  }'

# Search for the log
curl http://localhost:8000/api/v1/logs/search?query=quickstart

# Check health
curl http://localhost:8000/health
```

## Configuration Options

### Minimal Configuration (No Persistence)

```yaml
# values-minimal.yaml
persistence:
  elasticsearch:
    enabled: false
  prometheus:
    enabled: false
  grafana:
    enabled: false

resources:
  elasticsearch:
    limits:
      memory: 1Gi
```

Install:
```bash
helm install log-aggregation . -n logging -f values-minimal.yaml
```

### Production Configuration

```yaml
# values-production.yaml
replicaCount: 2

persistence:
  elasticsearch:
    enabled: true
    size: 50Gi
    storageClass: fast-ssd
  prometheus:
    enabled: true
    size: 20Gi
  grafana:
    enabled: true
    size: 5Gi

resources:
  elasticsearch:
    limits:
      cpu: 4000m
      memory: 8Gi
    requests:
      cpu: 2000m
      memory: 4Gi

grafana:
  adminPassword: "your-very-secure-password"

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: logs.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: logs-tls
      hosts:
        - logs.example.com
```

Install:
```bash
helm install log-aggregation . -n logging -f values-production.yaml
```

## Upgrading

```bash
# Upgrade with new values
helm upgrade log-aggregation . -n logging \
  --set image.tag=1.1.0 \
  --reuse-values

# Or upgrade with values file
helm upgrade log-aggregation . -n logging -f values-production.yaml
```

## Uninstallation

```bash
# Uninstall the release
helm uninstall log-aggregation -n logging

# Delete PVCs (if you want to remove all data)
kubectl delete pvc -n logging -l app.kubernetes.io/name=log-aggregration-system

# Delete namespace
kubectl delete namespace logging
```

## Troubleshooting

### Pod not starting

```bash
# Describe pod
kubectl describe pod -n logging -l app.kubernetes.io/name=log-aggregration-system

# Check init container logs
kubectl logs -n logging $POD_NAME -c wait-for-elasticsearch

# Check main container logs
kubectl logs -n logging $POD_NAME -c log-aggregator
```

### Elasticsearch issues

```bash
# Check Elasticsearch logs
kubectl logs -n logging $POD_NAME -c elasticsearch

# Check Elasticsearch health
kubectl exec -n logging $POD_NAME -c elasticsearch -- curl -s http://localhost:9200/_cluster/health
```

### Resource issues

```bash
# Check resource usage
kubectl top pod -n logging

# Check events
kubectl get events -n logging --sort-by='.lastTimestamp'
```

## Next Steps

1. **Configure Grafana Dashboards**: Import custom dashboards for your logs
2. **Set up Alerts**: Configure Prometheus alerting rules
3. **Enable Authentication**: Set up OAuth or LDAP for Grafana
4. **Backup Strategy**: Configure regular backups of Elasticsearch data
5. **Scale Up**: Increase replicas and resources based on load

## Support

For issues and questions:
- GitHub: https://github.com/sysadmi-exe/log-aggregation-system/issues
- Documentation: See [README.md](README.md)
