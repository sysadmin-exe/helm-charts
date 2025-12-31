# Terraform deployment for log-aggregation-system

This folder provisions the Helm release into an **existing** Kubernetes cluster. The structure is environment-aware (dev, staging, prod) and uses a reusable Helm module.

## Layout
- `modules/helm_release`: Reusable module that installs the chart from the repository root.
- `envs/<env>`: Environment configurations and values overrides.
  - `main.tf`: Providers + module wiring.
  - `variables.tf`: Inputs (kubeconfig path/context, namespace, etc.).
  - `values-<env>.yaml`: Environment-specific overrides merged with the chart defaults.

## Prerequisites
- Terraform >= 1.6
- Access to the target cluster; kubeconfig present locally (no cluster creation is done here).
- Helm provider can reach the cluster using your kubeconfig/context.
- (Recommended) Configure a remote backend (e.g., S3 + DynamoDB, GCS, or Azure Storage) by editing/adding `backend` blocks in each environment.

## Usage
1. Select an environment, e.g. dev:
   ```bash
   cd terraform/envs/dev
   terraform init 
   terraform plan
   terraform apply
   ```

2. Outputs will show the release name, namespace, revision, and status.

## Best practices baked in
- Namespaces are managed via Terraform (instead of Helm `create_namespace`) for idempotence.
- Helm is run atomically with rollback on failure and waits for readiness.
- Values are split per-environment; sensitive overrides can go into `set_sensitive_values` via tfvars or environment variables.
- Provider versions are pinned; timeouts are configurable per environment.
- Keeps release history bounded (`max_history`) to reduce clutter.

## Customization tips
- Update `values-<env>.yaml` to tune resources, ingress hosts, autoscaling, and persistence.
- Add secrets via external secret stores (e.g., Vault, External Secrets) rather than embedding in values files.
- If the chart is published remotely instead of local, set `chart_path` in the module call to the repo URL and provide `chart_version`.
