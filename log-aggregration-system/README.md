# Log Aggregation System Helm Chart

A comprehensive Helm chart for deploying a complete log aggregation system  on Kubernetes.

## Overview

This chart deploys a single-pod architecture containing:
- **Log Aggregation Application** - FastAPI-based log collection and search API
- **Elasticsearch** - Log storage and search backend
- **OpenTelemetry Collector** - Metrics, traces, and logs collection

## Architecture

All services run as containers in a single pod, communicating via localhost:

```
┌─────────────────────────────────────────┐
│                 Pod                     │
│                                         │
│  ┌──────────────┐  ┌──────────────────┐ │
│  │ Log          │→ │ Elasticsearch    │ │
│  │ Aggregator   │  │                  │ │
│  │ :8000        │  │ :9200           │ │
│  └──────────────┘  └──────────────────┘ │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │ OTEL Collector                     │ │
│  │ :4317/:4318                        │ │
│  └────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Persistent Volume provisioner (for stateful storage)
- 4GB+ memory available for the pod

## Installation

### Quick Start

```bash
# Install with custom values
cd log-aggregation-system 
helm install log-aggregation-system . -n log-aggregation-system --create-namespace  --set persistence.elasticsearch.size=20Gi
```

## Configuration

### Key Configuration Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of pod replicas | `1` |
| `image.repository` | Log aggregator image repository | `log-aggregation-system` |
| `image.tag` | Log aggregator image tag | `1.0.0` |
| `config.logLevel` | Application log level | `INFO` |
| `config.storageBackend` | Storage backend (elasticsearch) | `elasticsearch` |
| `podDisruptionBudget.enabled` | Enable PodDisruptionBudget | `true` |
| `networkPolicy.enabled` | Enable NetworkPolicy | `false` |
| `autoscaling.enabled` | Enable HorizontalPodAutoscaler | `false` |

### Service Ports

| Service | Port | Description |
|---------|------|-------------|
| Log Aggregator | 8000 | Main API endpoint |
| Elasticsearch | 9200 | Elasticsearch HTTP API |
| OTEL Collector | 4317/4318 | OTLP gRPC/HTTP |

### Resource Configuration

Default resource limits:

```yaml
resources:
  logAggregator:
    limits: {cpu: 1000m, memory: 512Mi}
    requests: {cpu: 200m, memory: 256Mi}
  elasticsearch:
    limits: {cpu: 2000m, memory: 2Gi}
    requests: {cpu: 500m, memory: 1Gi}
  otelCollector:
    limits: {cpu: 500m, memory: 512Mi}
    requests: {cpu: 100m, memory: 128Mi}
```

### Persistence

Enable persistent storage for stateful services:

```yaml
persistence:
  elasticsearch:
    enabled: true
    size: 10Gi
    storageClass: ""  # Use default storage class
```

## Usage

### Accessing Services

After installation, get the service details:

```bash
kubectl get svc -n logging
```

#### Port Forward for Local Access

```bash
# Log Aggregator API
kubectl port-forward -n logging svc/log-aggregation 8000:8000

# Elasticsearch
kubectl port-forward -n logging svc/log-aggregation 9200:9200
```

#### Ingress

Enable ingress for external access:

```yaml
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: log-aggregation.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: log-aggregation-tls
      hosts:
        - log-aggregation.example.com
```

### API Endpoints

The log aggregator exposes:

- `GET /health` - Health check
- `GET /metrics` - Metrics endpoint
- `POST /api/v1/logs/ingest` - Ingest logs
- `GET /api/v1/logs/search` - Search logs
- `GET /api/v1/logs/query` - Query logs

Example log ingestion:

```bash
curl -X POST http://localhost:8000/api/v1/logs/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "logs": [
      {
        "timestamp": "2025-12-30T10:00:00Z",
        "level": "INFO",
        "message": "Application started",
        "source": "api-gateway"
      }
    ]
  }'
```


## High Availability & Best Practices

### Pod Disruption Budget

Enabled by default to ensure availability during voluntary disruptions:

```yaml
podDisruptionBudget:
  enabled: true
  minAvailable: 1
```

This prevents Kubernetes from evicting the last available pod during:
- Node drains
- Cluster upgrades
- Node maintenance

### Horizontal Pod Autoscaling

Enable HPA for automatic scaling based on CPU/Memory:

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80
```

**Note:** When using HPA with this single-pod architecture, consider:
- Each replica contains all bundled services (resource-intensive)
- Elasticsearch data replication across pods
- Pod affinity/anti-affinity rules for distribution

### Network Policy

Enable NetworkPolicy for secure pod-to-pod communication:

```yaml
networkPolicy:
  enabled: true
  ingress:
    namespaceSelector:
      matchLabels:
        name: app-namespace
    podSelector:
      matchLabels:
        app: allowed-app
  egress:
    restrictExternal: false
```

This restricts:
- Ingress traffic to specific namespaces/pods
- Egress traffic (optional)
- Enhances security posture

### Resource Management

Set appropriate resource limits:

```yaml
resources:
  logAggregator:
    limits: {cpu: 1000m, memory: 512Mi}
    requests: {cpu: 200m, memory: 256Mi}
  elasticsearch:
    limits: {cpu: 2000m, memory: 2Gi}
    requests: {cpu: 500m, memory: 1Gi}
```

### Security Best Practices

The chart implements:
- ✅ Non-root containers (`runAsUser: 1000`)
- ✅ Read-only root filesystem
- ✅ Dropped all capabilities
- ✅ Security contexts enforced
- ✅ Resource limits defined
- ✅ PodDisruptionBudget for availability
- ✅ NetworkPolicy support
- ✅ Secrets for sensitive data

## Upgrading

```bash
# Update the chart
helm upgrade log-aggregation-system sysadmin-exe/log-aggregation-system \
  --namespace logging \
  --reuse-values \
  --set image.tag=1.1.0
```

## Uninstallation

```bash
helm uninstall log-aggregation -n logging

# Optionally delete PVCs
kubectl delete pvc -n logging -l app.kubernetes.io/name=log-aggregation-system
```

## Troubleshooting

### Pod Not Starting

Check pod events:
```bash
kubectl describe pod -n logging -l app.kubernetes.io/name=log-aggregration-system
```

Check container logs:
```bash
# Log aggregator
kubectl logs -n logging -l app.kubernetes.io/name=log-aggregration-system -c log-aggregator

# Elasticsearch
kubectl logs -n logging -l app.kubernetes.io/name=log-aggregration-system -c elasticsearch
```

### Elasticsearch Initialization

Elasticsearch may take 60-90 seconds to start.

### Memory Issues

If pods are OOMKilled, increase memory limits:

```yaml
resources:
  elasticsearch:
    limits:
      memory: 4Gi
```

### Storage Issues

Ensure PersistentVolumes are available:

```bash
kubectl get pv
kubectl get pvc -n logging
```

## Development

### Local Testing

```bash
# Lint the chart
helm lint .

# Test rendering
helm template log-aggregation . --debug

# Dry run install
helm install log-aggregation . --dry-run --debug
```

### Building the Application Image

```bash
cd ../../log-aggregation-system
docker build -t log-aggregation-system:1.0.0 .
docker push your-registry/log-aggregation-system:1.0.0
```

## Security

- Non-root containers (runAsUser: 1000)
- Read-only root filesystem
- Dropped all capabilities
- Elasticsearch security disabled for simplicity (enable for production)

### Production Recommendations

1. Enable Elasticsearch security:
   ```yaml
   sidecars:
     elasticsearch:
       env:
         xpackSecurityEnabled: true
   ```

  2. Enable NetworkPolicies
  3. Use TLS for ingress
  4. Enable Pod Security Standards
  5. Implement backup strategy for persistent volumes

## License

MIT License - see LICENSE file

## Support

For issues and questions:
- GitHub Issues: https://github.com/sysadmin-exe/log-aggregation-system/issues
