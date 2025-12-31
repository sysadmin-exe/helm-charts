variable "release_name" {
  type        = string
  description = "Helm release name"
}

variable "cluster_name" {
  type        = string
  description = "Name of EKS Cluster"
}

variable "namespace" {
  type        = string
  description = "Target Kubernetes namespace"
}

variable "create_namespace" {
  type        = bool
  description = "Whether to create/manage the namespace"
  default     = true
}

variable "chart_path" {
  type        = string
  description = "Path to the Helm chart (local or remote)"
}

variable "chart_version" {
  type        = string
  description = "Optional chart version (required when using a remote chart)"
  default     = null
}

variable "values_files" {
  type        = list(string)
  description = "List of values file paths to merge for this release"
  default     = []
}

variable "set_values" {
  type        = map(string)
  description = "Inline Helm values (non-sensitive)"
  default     = {}
}

variable "set_sensitive_values" {
  type        = map(string)
  description = "Inline Helm values (sensitive)"
  default     = {}
}

variable "labels" {
  type        = map(string)
  description = "Labels applied to managed resources such as the namespace"
  default     = {}
}

variable "dependency_update" {
  type        = bool
  description = "Run 'helm dependency update' before install/upgrade"
  default     = true
}

variable "wait" {
  type        = bool
  description = "Wait until all resources are in a ready state"
  default     = true
}

variable "atomic" {
  type        = bool
  description = "Roll back changes on failure"
  default     = true
}

variable "timeout" {
  type        = number
  description = "Timeout for Helm operations in seconds"
  default     = 600
}

variable "max_history" {
  type        = number
  description = "Maximum number of release revisions to keep"
  default     = 5
}

variable "disable_webhooks" {
  type        = bool
  description = "Disable waiting for webhooks during Helm operations"
  default     = false
}
