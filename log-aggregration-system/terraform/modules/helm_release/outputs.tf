output "release_name" {
  description = "Helm release name"
  value       = helm_release.this.name
}

output "namespace" {
  description = "Kubernetes namespace where the release is installed"
  value       = helm_release.this.namespace
}

output "revision" {
  description = "Helm release revision"
  value       = helm_release.this.metadata[0].revision
}

output "status" {
  description = "Helm release status"
  value       = helm_release.this.status
}
