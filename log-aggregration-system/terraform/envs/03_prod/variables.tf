variable "kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig for the target cluster"
  default     = "~/.kube/config"
}

variable "kube_context" {
  type        = string
  description = "Optional kubeconfig context name"
  default     = null
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace for this environment"
  default     = "log-aggregation-system-prod"
}

variable "create_namespace" {
  type        = bool
  description = "Create the namespace if it does not exist"
  default     = true
}

variable "log_level" {
  type        = string
  description = "Log level for the application"
  default     = "WARN"
}

variable "extra_values_files" {
  type        = list(string)
  description = "Additional values files to merge (absolute or relative paths)"
  default     = []
}

variable "timeout" {
  type        = number
  description = "Helm operation timeout in seconds"
  default     = 1200
}
