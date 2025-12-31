# Optional namespace management to avoid relying on Helm's create_namespace flag
resource "kubernetes_namespace_v1" "managed" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name   = var.namespace
    labels = merge(var.labels, { "app.kubernetes.io/managed-by" = "terraform" })
  }
}

resource "helm_release" "this" {
  name              = var.release_name
  namespace         = var.namespace
  chart             = var.chart_path
  version           = var.chart_version
  dependency_update = var.dependency_update
  wait              = var.wait
  atomic            = var.atomic
  cleanup_on_fail   = true
  max_history       = var.max_history
  timeout           = var.timeout
  disable_webhooks  = var.disable_webhooks

  create_namespace = false

  values = [for vf in var.values_files : file(vf)]

  set = concat([for k, v in var.set_values : {
    name  = k
    value = v
    }],
    [
      for k, v in var.set_sensitive_values : {
        name  = k
        value = v
  }])

  depends_on = [kubernetes_namespace_v1.managed]
}
