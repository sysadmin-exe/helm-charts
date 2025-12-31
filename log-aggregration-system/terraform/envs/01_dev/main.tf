locals {
  environment  = "dev"
  release_name = "log-aggregation-system"
  cluster_name = "app-cluster-dev"
  chart_path   = abspath("${path.module}/../../..")
  values_files = [
    abspath("${path.module}/values-dev.yaml"),
  ]
  namespace        = "log-aggregation-system-dev"
  create_namespace = true
  log_level        = "DEBUG"
  timeout          = 600
}

module "log_aggregation_system" {
  source = "../../modules/helm_release"

  release_name     = local.release_name
  cluster_name     = local.cluster_name
  namespace        = local.namespace
  create_namespace = local.create_namespace
  chart_path       = local.chart_path
  values_files     = local.values_files

  set_values = {
    "config.logLevel" = local.log_level
  }

  labels = {
    "environment" = local.environment
  }

  timeout = local.timeout
}

output "status" {
  value = module.log_aggregation_system.status
}